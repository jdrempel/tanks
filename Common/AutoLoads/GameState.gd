extends Node

var menus_scene = preload("res://Scenes/Menus.tscn")

remotesync var start_level_data := {}
remotesync var current_level_data := {}
var current_level: Node
var game_paused := false

var last_checkpoint = 0

# Signals to let lobby GUI know what's going on.
signal start_level_changed()
signal all_players_loaded()
signal level_ended(outcome)
signal game_ended(outcome, stats_list)
signal game_error(what)


func _ready():
    Data.load_level_data()
    Data.load_player_colors()
    Data.load_enemy_types()

    start_level_data = Data.level_data.get_level_by_id("Level1")


func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("ui_cancel"):
        if is_instance_valid(current_level):
            if current_level.toggle_pause(not game_paused):
                game_paused = not game_paused
                Globals.menus.toggle_pause_menu(game_paused)


func resume_level() -> void:
    if is_instance_valid(current_level):
        if current_level.toggle_pause(false):
            game_paused = false
            Globals.menus.toggle_pause_menu(false)



func reset(hard: bool = false) -> void:
    start_level_data = {}
    current_level_data = {}
    if is_instance_valid(current_level):
        current_level.exit()
    current_level = null
    last_checkpoint = 0
    game_paused = false
    for child in get_children():
        child.queue_free()
    if hard:
        hard_reset_menus()


func hard_reset_menus() -> void:
    var old_menus = Globals.menus
    old_menus.queue_free()
    var new_menus = menus_scene.instance()
    yield(old_menus, "tree_exited")
    get_tree().get_root().add_child(new_menus, true)
    Globals.menus = new_menus


func set_all_start_level(level_data: Dictionary) -> void:
    if MetaManager.player_manager.peer:
        rpc("set_start_level", level_data)
    else:
        set_start_level(level_data)


remotesync func set_start_level(level_data: Dictionary) -> void:
    start_level_data = level_data
    emit_signal("start_level_changed")


func _set_player_ready():
    # Tell peer(s) we are ready to start.
    rpc("ready_to_start_level")
    if MetaManager.player_manager.players.size() <= 1 or \
            MetaManager.player_manager.type == Globals.PlayerManagers.COOP:
        emit_signal("all_players_loaded")


remote func ready_to_start_level() -> void:
    current_level.remote_loaded = true
    emit_signal("all_players_loaded")


remotesync func pre_begin_game():
    current_level_data = start_level_data
    Globals.menus.hide_all()
    assert(current_level_data != null and current_level_data != {})


func begin_game():
    rpc("pre_begin_game")
    rpc("setup_player_stats", MetaManager.player_manager.players)
    rpc("begin_level", MetaManager.player_manager.players)


remotesync func setup_player_stats(player_data: Dictionary) -> void:
    for player_id in player_data:
        if not player_data[player_id].active:
            continue
        MetaManager.stats_manager.add_player_stats_container(player_id)


remotesync func begin_level(player_data: Dictionary) -> void:
    var root = get_tree().get_root()
    MetaManager.player_manager.players = player_data
    if root.has_node(current_level_data.id):
        return

    var current_level_index = Data.level_data.get_index_by_id(current_level_data.id)
    var reached_checkpoint = false
    if current_level_index > 0 and current_level_index % Globals.CHECKPOINT_INTERVAL == 0:
        # max(...) in case we already got further but backtracked for some reason
        var new_last_checkpoint = max(current_level_index, last_checkpoint)
        if new_last_checkpoint != last_checkpoint:
            reached_checkpoint = true
            last_checkpoint = new_last_checkpoint
            # emit_signal("checkpoint_reached", last_checkpoint)

    var black = preload("res://Scenes/UI/FadeBlack.tscn").instance()
    add_child(black)
    black.fade_from_black()

    var current_level_scene = load("res://Scenes/Levels/%s.tscn" % current_level_data.id)
    current_level = current_level_scene.instance()
    root.add_child(current_level)
    current_level.set_name(current_level_data.id)
    current_level.connect("level_loaded", self, "_set_player_ready")
    current_level.enter(player_data, reached_checkpoint)


remotesync func win_level():
    current_level_data = Data.level_data.get_level_by_index(current_level_data.index + 1)
    end_level(Globals.Outcome.Win)
    yield(current_level, "debrief_over")
    if current_level_data.empty():
        emit_signal("game_ended", Globals.Outcome.Win, MetaManager.stats_manager.stats)
        # TODO delay this
        for child in get_children():
            child.queue_free()
    else:
        yield(current_level, "tree_exited")
        begin_level(MetaManager.player_manager.players)


remotesync func lose_level():
    end_level(Globals.Outcome.Loss)
    yield(current_level, "debrief_over")
    print("game over")
    emit_signal("game_ended", Globals.Outcome.Loss, MetaManager.stats_manager.stats)
    # TODO delay this
    for child in get_children():
        child.queue_free()


func end_level(outcome: int):
    if not is_instance_valid(current_level):
        emit_signal("level_ended", outcome)
        return
    current_level.end(outcome)
    emit_signal("level_ended", outcome)
    yield(current_level, "debrief_over")
    current_level.disconnect("level_loaded", self, "_set_player_ready")
    print("exiting level")
    current_level.exit()
