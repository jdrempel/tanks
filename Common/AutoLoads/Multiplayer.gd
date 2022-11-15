extends Node


const DEFAULT_PORT = 1337

# Max number of players.
const MAX_PEERS = 2

var peer = null

var player_name := ""

var players := {}  # { player_id: { name: "", ready: false, color: "" } }

signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal server_disconnected()
signal all_players_ready()
signal player_unready()
signal remote_player_color_changed(to_color)


func _ready() -> void:
    get_tree().connect("network_peer_connected", self, "_peer_connected")
    get_tree().connect("network_peer_disconnected", self,"_peer_disconnected")
    get_tree().connect("connected_to_server", self, "_connected_ok")
    get_tree().connect("connection_failed", self, "_connected_fail")
    get_tree().connect("server_disconnected", self, "_server_disconnected")


func host_game(new_player_name: String, port: String):
    self.player_name = new_player_name
    peer = NetworkedMultiplayerENet.new()
    var port_num = port.to_int() if port.strip_edges().length() > 0 else DEFAULT_PORT
    peer.create_server(port_num, MAX_PEERS)
    get_tree().set_network_peer(peer)
    players[1] = { name=new_player_name, ready=false, color="Blue" }


func join_game(ip: String, port: String, new_player_name: String):
    self.player_name = new_player_name
    peer = NetworkedMultiplayerENet.new()
    var port_num = port.to_int() if port.strip_edges().length() > 0 else DEFAULT_PORT
    peer.create_client(ip, port_num)
    get_tree().set_network_peer(peer)
    var my_player_id = get_tree().get_network_unique_id()
    players[my_player_id] = { name=new_player_name, ready=false, color="Red" }


func disconnect_from_game():
    peer = null
    get_tree().set_network_peer(null)
    players.clear()
    player_name = ""
    GameState.reset()


func _peer_connected(id):
    # Beginning of player registration - trade player data
    var my_player_id = get_tree().get_network_unique_id()
    rpc_id(id, "register_player", players[my_player_id])
    print("Registered my player %s on remote %d" % [players[my_player_id], id])


func _peer_disconnected(id):
    # Beginning of disconnect/deregistration process
    if is_instance_valid(GameState.current_level):
        # Game is in progress
        GameState.current_level.rpc("despawn_player", id)
        # TODO in the future we could allow reconnection
        GameState.emit_signal("game_error", "Player " + players[id].name + " disconnected")
        GameState.end_level(Globals.Outcome.Error)
    unregister_player(id)


func _connected_ok():
    # Client: Connected successfully to server
    emit_signal("connection_succeeded")


func _connected_fail():
    # Client: Unable to connect to server
    disconnect_from_game()
    emit_signal("connection_failed")


func _server_disconnected():
    # Client: Detected server port shutdown
    disconnect_from_game()
    GameState.emit_signal("game_error", "Server disconnected")
    GameState.reset()
    emit_signal("server_disconnected")


remote func register_player(new_player: Dictionary) -> void:
    # Add remote player to the players list
    var player_id = get_tree().get_rpc_sender_id()
    players[player_id] = new_player
    emit_signal("player_list_changed")


func unregister_player(player_id: int):
    # Remove remote player from the players list
    players.erase(player_id)
    emit_signal("player_list_changed")


func check_all_players_ready() -> bool:
    for player_id in players:
        if not players[player_id].ready:
            return false
    return true


func set_lobby_player_ready(val: bool) -> void:
    # Set ready status of local player
    var my_player_id = get_tree().get_network_unique_id()
    players[my_player_id].ready = val
    emit_signal("player_list_changed")
    if val:
        if check_all_players_ready():
            emit_signal("all_players_ready")
    else:
        emit_signal("player_unready")
    for player_id in players:
        if player_id == my_player_id:
            continue
        rpc_id(player_id, "request_lobby_player_ready", val)


remote func request_lobby_player_ready(ready: bool) -> void:
    # Set ready status of remote player
    var player_id = get_tree().get_rpc_sender_id()
    players[player_id].ready = ready
    if ready:
        if check_all_players_ready():
            emit_signal("all_players_ready")
    else:
        emit_signal("player_unready")
    emit_signal("player_list_changed")


func set_lobby_player_color(color_name: String) -> void:
    # Set tank color of local player on remote lobby
    var my_player_id = get_tree().get_network_unique_id()
    players[my_player_id].color = color_name
    print("Local player %d color is %s" % [my_player_id, color_name])
    for player_id in players:
        if player_id == my_player_id:
            continue
        rpc_id(player_id, "request_lobby_player_color", color_name)


remote func request_lobby_player_color(color_name: String) -> void:
    # Set tank color of remote player
    var player_id = get_tree().get_rpc_sender_id()
    players[player_id].color = color_name
    print("Remote player %d color is %s" % [player_id, color_name])
    emit_signal("remote_player_color_changed", color_name)


func set_all_start_level(level_id: String) -> void:
    rpc_id(0, "request_start_level_change", level_id)


puppet func request_start_level_change(level_id: String) -> void:
    Globals.menus.set_remote_start_level(level_id)
