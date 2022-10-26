extends Node

# Default game server port. Can be any number between 1024 and 49151.
# Not on the list of registered or common ports as of November 2020:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT = 10567

# Max number of players.
const MAX_PEERS = 2

var peer = null
var is_host := false

# Name for my player.
var player_name := "Tank"

# Names for remote players in id:name format.
var players := {}
var players_ready := []

# Count of living enemies
puppetsync var enemies_alive := 0
# Count of living players
puppetsync var players_alive := 0

remotesync var start_level_data := {}
remotesync var current_level_data := {}
var current_level: Node

# Signals to let lobby GUI know what's going on.
signal player_list_changed()
signal start_level_changed()
signal connection_failed()
signal connection_succeeded()
signal all_players_died()
signal all_players_ready()
signal level_loaded()
signal level_ended(outcome)
signal game_ended()
signal game_error(what)


# Callback from SceneTree.
func _player_connected(id):
    # Registration of a client beings here, tell the connected player that we are here.
    rpc_id(id, "register_player", player_name)


# Callback from SceneTree.
func _player_disconnected(id):
    if has_node("/root/Level"): # Game is in progress.
        current_level.rpc("despawn_player", id)
        if get_tree().is_network_server():
            # TODO in the future we could allow reconnection
            emit_signal("game_error", "Player " + players[id] + " disconnected")
            end_level(Globals.Outcome.Error)
    unregister_player(id)


# Callback from SceneTree, only for clients (not server).
func _connected_ok():
    # We just connected to a server
    emit_signal("connection_succeeded")


# Callback from SceneTree, only for clients (not server).
func _server_disconnected():
    emit_signal("game_error", "Server disconnected")
    end_level(Globals.Outcome.Error)


# Callback from SceneTree, only for clients (not server).
func _connected_fail():
    get_tree().set_network_peer(null) # Remove peer
    emit_signal("connection_failed")


func _on_enemy_destroyed():
    var enemies_count = current_level.get_node("Navigation/Enemies").get_child_count()
    if enemies_count == 0:
        call_deferred("win_level")


func _on_player_destroyed():
    var players_count = current_level.get_node("Players").get_child_count()
    if players_count == 0:
        call_deferred("lose_level")


func set_all_start_level(level_data):
    rpc("set_start_level", level_data)


# if this breaks change back to puppetsync
remotesync func add_living_player():
    if get_tree().get_rpc_sender_id() != 1:
        return
    players_alive += 1


remotesync func add_living_enemy():
    if get_tree().get_rpc_sender_id() != 1:
        return
    enemies_alive += 1


remotesync func set_start_level(level_data):
    start_level_data = level_data
    emit_signal("start_level_changed")


# Lobby management functions.

remote func register_player(new_player_name):
    var id = get_tree().get_rpc_sender_id()
    players[id] = new_player_name
    emit_signal("player_list_changed")


func unregister_player(id):
    players.erase(id)
    emit_signal("player_list_changed")


func _set_player_ready():
    if not get_tree().is_network_server():
        # Tell server we are ready to start.
        rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())
    elif players.size() == 0:
        emit_signal("all_players_ready")


remote func post_start_level():
    emit_signal("level_loaded")
    # get_tree().set_pause(false) # Unpause and unleash the level!


remote func ready_to_start(id):
    assert(get_tree().is_network_server())  # This doesn't make sense given _set_player_ready's first line

    if not id in players_ready:
        players_ready.append(id)

    if players_ready.size() == players.size():
        emit_signal("all_players_ready")


func host_game(new_player_name):
    player_name = new_player_name
    peer = NetworkedMultiplayerENet.new()
    peer.create_server(DEFAULT_PORT, MAX_PEERS)
    get_tree().set_network_peer(peer)
    is_host = true


func join_game(ip, new_player_name):
    player_name = new_player_name
    peer = NetworkedMultiplayerENet.new()
    peer.create_client(ip, DEFAULT_PORT)
    get_tree().set_network_peer(peer)
    is_host = false


remotesync func pre_begin_game():
    current_level_data = start_level_data
    assert(current_level_data != null and current_level_data != {})


func begin_game():
    rpc("pre_begin_game")
    rpc("begin_level", players)


remotesync func begin_level(p):
    var root = get_tree().get_root()
    players = p
    if root.has_node(current_level_data.id):
        return
    var current_level_scene = load("res://Scenes/Levels/%s.tscn" % current_level_data.id)
    current_level = current_level_scene.instance()
    root.add_child(current_level)
    current_level.set_name(current_level_data.id)
    current_level.connect("level_loaded", self, "_set_player_ready")
    current_level.enter(p)


func win_level():
    current_level_data = Globals.level_data.get_level_by_index(current_level_data.index + 1)
    end_level(Globals.Outcome.Win)


func lose_level():
    end_level(Globals.Outcome.Loss)
    emit_signal("game_ended")


func end_level(outcome: int):
    current_level.end(outcome)
    players_alive = 0
    enemies_alive = 0
    emit_signal("level_ended", outcome)
    yield($"/root/Lobby", "debrief_over")
    current_level.exit()

    if current_level_data.size() == 0:
        emit_signal("game_ended")
        return
    else:
        yield(current_level, "tree_exited")
        rpc("begin_level", players)


func _ready():
    Globals.load_level_data()

    get_tree().connect("network_peer_connected", self, "_player_connected")
    get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
    get_tree().connect("connected_to_server", self, "_connected_ok")
    get_tree().connect("connection_failed", self, "_connected_fail")
    get_tree().connect("server_disconnected", self, "_server_disconnected")
