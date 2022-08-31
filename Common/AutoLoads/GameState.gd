extends Node

# Default game server port. Can be any number between 1024 and 49151.
# Not on the list of registered or common ports as of November 2020:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT = 10567

# Max number of players.
const MAX_PEERS = 2

var peer = null
var is_host = false

# Name for my player.
var player_name = "Tank"

# Names for remote players in id:name format.
var players = {}
var players_ready = []

# Count of living enemies
var enemies_alive = 0
# Count of living players
var players_alive = 0

# Names of all level scene files
var levels = []
var start_level = "Level1.tscn"

# Signals to let lobby GUI know what's going on.
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal all_players_died()
signal game_ended()
signal game_error(what)


# Callback from SceneTree.
func _player_connected(id):
    # Registration of a client beings here, tell the connected player that we are here.
    rpc_id(id, "register_player", player_name)


# Callback from SceneTree.
func _player_disconnected(id):
    if has_node("/root/Main"): # Game is in progress.
        if get_tree().is_network_server():
            emit_signal("game_error", "Player " + players[id] + " disconnected")
            end_game()
    else: # Game is not in progress.
        # Unregister this player.
        unregister_player(id)


# Callback from SceneTree, only for clients (not server).
func _connected_ok():
    # We just connected to a server
    emit_signal("connection_succeeded")


# Callback from SceneTree, only for clients (not server).
func _server_disconnected():
    emit_signal("game_error", "Server disconnected")
    end_game()


# Callback from SceneTree, only for clients (not server).
func _connected_fail():
    get_tree().set_network_peer(null) # Remove peer
    emit_signal("connection_failed")


func _on_enemy_destroyed():
    enemies_alive -= 1
    if enemies_alive == 0:
        win_game()


func _on_player_destroyed():
    players_alive -= 1
    if players_alive == 0:
        lose_game()


func set_all_start_level(level):
    rpc("set_start_level", level)


remotesync func add_living_player():
    players_alive += 1


remotesync func add_living_enemy():
    enemies_alive += 1


remotesync func set_start_level(level):
    start_level = level


# Lobby management functions.

remote func register_player(new_player_name):
    var id = get_tree().get_rpc_sender_id()
    print(id)
    players[id] = new_player_name
    emit_signal("player_list_changed")


func unregister_player(id):
    players.erase(id)
    emit_signal("player_list_changed")


remote func pre_start_game(spawn_points):
    # Change scene.
    var world = load("res://Scenes/Levels/" + start_level).instance()
    get_tree().get_root().add_child(world)

    get_tree().get_root().get_node("Lobby").hide()

    for enemy in world.get_node("Navigation/Enemies").get_children():
        enemy.set_network_master(1)  # server controls all enemies

    var player_scene = load("res://Entities/Players/Player.tscn")

    for p_id in spawn_points:
        var spawn_pos = world.get_node("SpawnPoints/" + str(spawn_points[p_id])).global_transform.origin
        var player = player_scene.instance()

        var player_num = 1
        if str(p_id) != str(player_num):
            player_num = 2
        player.set_name("Player" + str(player_num)) # Use unique ID as node name.
        player.global_transform.origin = spawn_pos
        player.set_network_master(p_id) #set unique id as master.

        if p_id == get_tree().get_network_unique_id():
            # If node for this peer id, set name.
            pass  # player.set_player_name(player_name)
        else:
            # Otherwise set name from peer.
            pass  # player.set_player_name(players[p_id])

        world.get_node("Players").add_child(player)

    # Set up score.
#	world.get_node("Score").add_player(get_tree().get_network_unique_id(), player_name)
#	for pn in players:
#		world.get_node("Score").add_player(pn, players[pn])

    if not get_tree().is_network_server():
        # Tell server we are ready to start.
        rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())
    elif players.size() == 0:
        post_start_game()


remote func post_start_game():
    get_tree().set_pause(false) # Unpause and unleash the game!


remote func ready_to_start(id):
    assert(get_tree().is_network_server())

    if not id in players_ready:
        players_ready.append(id)

    if players_ready.size() == players.size():
        for p in players:
            rpc_id(p, "post_start_game")
        post_start_game()


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


func get_player_list():
    return players.values()


func get_player_name():
    return player_name


func begin_game():
    assert(get_tree().is_network_server())

    # Create a dictionary with peer id and respective spawn points, could be improved by randomizing.
    var spawn_points = {}
    spawn_points[1] = 0 # Server in spawn point 0.
    var spawn_point_idx = 1
    for p in players:
        spawn_points[p] = spawn_point_idx
        spawn_point_idx += 1
    # Call to pre-start game with the spawn points.
    for p in players:
        rpc_id(p, "pre_start_game", spawn_points)

    pre_start_game(spawn_points)


func win_game():
    end_game()


func lose_game():
    end_game()


func end_game():
    if has_node("/root/Level"): # Game is in progress.
        # End it
        get_node("/root/Level").queue_free()

    emit_signal("game_ended")
    players_alive = 0
    enemies_alive = 0
    players.clear()
    get_tree().set_pause(true)


func _ready():
    get_tree().connect("network_peer_connected", self, "_player_connected")
    get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
    get_tree().connect("connected_to_server", self, "_connected_ok")
    get_tree().connect("connection_failed", self, "_connected_fail")
    get_tree().connect("server_disconnected", self, "_server_disconnected")