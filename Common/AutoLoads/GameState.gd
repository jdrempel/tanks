extends Node

remotesync var start_level_data := {}
remotesync var current_level_data := {}
var current_level: Node

# Signals to let lobby GUI know what's going on.
signal start_level_changed()
signal all_players_loaded()
signal level_ended(outcome)
signal game_ended()
signal game_error(what)


func _ready():
    Data.load_level_data()


func _on_enemy_destroyed():
    if not is_instance_valid(current_level):
        return
    var enemies_count = current_level.get_node("Navigation/Enemies").get_child_count()
    if enemies_count == 0 and get_tree().is_network_server():
        call_deferred("rpc", "win_level")


func _on_player_destroyed():
    if not is_instance_valid(current_level):
        return
    var players_count = current_level.get_node("Players").get_child_count()
    if players_count == 0 and get_tree().is_network_server():
        call_deferred("rpc", "lose_level")


func set_all_start_level(level_data: Dictionary) -> void:
    rpc("set_start_level", level_data)


remotesync func set_start_level(level_data: Dictionary) -> void:
    start_level_data = level_data
    emit_signal("start_level_changed")


func _set_player_ready():
    # Tell peer(s) we are ready to start.
    rpc("ready_to_start_level")
    if Multiplayer.players.size() <= 1:
        emit_signal("all_players_loaded")


remote func ready_to_start_level() -> void:
    current_level.remote_loaded = true
    emit_signal("all_players_loaded")


remotesync func pre_begin_game():
    current_level_data = start_level_data
    Globals.menus.hide()
    assert(current_level_data != null and current_level_data != {})


func begin_game():
    rpc("pre_begin_game")
    rpc("begin_level", Multiplayer.players)


remotesync func begin_level(player_data: Dictionary):
    var root = get_tree().get_root()
    Multiplayer.players = player_data
    if root.has_node(current_level_data.id):
        return
    var current_level_scene = load("res://Scenes/Levels/%s.tscn" % current_level_data.id)
    current_level = current_level_scene.instance()
    root.add_child(current_level)
    current_level.set_name(current_level_data.id)
    current_level.connect("level_loaded", self, "_set_player_ready")
    current_level.enter(player_data)


remotesync func win_level():
    current_level_data = Data.level_data.get_level_by_index(current_level_data.index + 1)
    end_level(Globals.Outcome.Win)
    yield(current_level, "debrief_over")
    if current_level_data.empty():
        emit_signal("game_ended")
    else:
        yield(current_level, "tree_exited")
        begin_level(Multiplayer.players)


remotesync func lose_level():
    end_level(Globals.Outcome.Loss)
    emit_signal("game_ended")


func end_level(outcome: int):
    current_level.end(outcome)
    emit_signal("level_ended", outcome)
    yield(current_level, "debrief_over")
    current_level.disconnect("level_loaded", self, "_set_player_ready")
    current_level.exit()
