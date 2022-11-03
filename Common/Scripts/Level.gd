extends Node

const NODE_NAME = "Level"

var remote_loaded = false

var paused = false
var timer_running := false
var wall_time := 0.0

signal level_loaded()
signal level_ended(outcome)
signal debrief_over()


func _process(delta: float) -> void:
    if Input.is_action_just_pressed("ui_cancel"):
        if Multiplayer.players.size() <= 1:
            print("game " + ("paused" if not paused else "unpaused"))
            set_paused(not paused)
    if timer_running:
        wall_time += delta


func get_wall_time() -> float:
    return wall_time


func _ready() -> void:
    connect("level_loaded", self, "_on_start_briefing")
    connect("level_ended", self, "_on_start_debriefing")


func set_paused(val: bool) -> void:
    paused = val
    timer_running = not val
    for ordnance in get_node("Ordnance").get_children():
        if ordnance is CPUParticles:
            ordnance.emitting = not val
        elif ordnance is Projectile or ordnance.has_method("set_paused"):
            ordnance.set_paused(val)
    for player in get_node("Players").get_children():
        player.set_paused(val)
    for enemy in get_node("Navigation/Enemies").get_children():
        enemy.set_paused(val)
        if not val and enemy.has_node("Cloaking"):
            enemy.get_node("Cloaking").engage()


func enter(players: Dictionary) -> void:
    var ordnance_root = Spatial.new()
    ordnance_root.set_name("Ordnance")
    add_child(ordnance_root)

    for enemy in $Navigation/Enemies.get_children():
        enemy.set_network_master(1)  # server controls all enemies

    var player_scene = preload("res://Entities/Players/Player.tscn")

    var spawn_points = get_spawn_points(players)
    for p_id in spawn_points:
        var spawn_pos = get_node("SpawnPoints/%d" % spawn_points[p_id]).global_transform
        var player = player_scene.instance()
        player.set_name(str(p_id)) # Use unique ID as node name.
        player.global_transform = spawn_pos
        player.set_network_master(p_id) # set unique id as master.

        $Players.add_child(player)

    emit_signal("level_loaded")
    yield(GameState, "all_players_loaded")
    start()


func start() -> void:
    # Fires after entry and all players loaded
    yield(self, "tree_entered")


func _on_start_briefing():
    $Briefing/Title.text = GameState.current_level_data.name
    $Briefing/EnemyCount.text = \
        "Enemy Tanks: %d" % GameState.current_level.get_node("Navigation/Enemies").get_child_count()
    $Briefing.show()
    get_tree().create_timer(Globals.BRIEF_TIME).connect("timeout", self, "_on_end_briefing")
    set_paused(true)


func _on_end_briefing():
    $Briefing.hide()
    set_paused(false)


func _on_start_debriefing(outcome: int):
    match outcome:
        Globals.Outcome.Loss:
            $Debriefing/Title.text = "Mission Failed"
        Globals.Outcome.Win:
            $Debriefing/Title.text = "Mission Cleared"
        _:
            $Debriefing/Title.text = "Something went wrong"
    $Debriefing/Time.text = "Time: %4.1f s" % GameState.current_level.get_wall_time()
    $Debriefing.show()
    get_tree().create_timer(Globals.DEBRIEF_TIME).connect("timeout", self, "_on_end_debriefing")


func _on_end_debriefing():
    $Debriefing.hide()
    emit_signal("debrief_over")


func end(outcome: int) -> void:
    # Fires after all players or all enemies destroyed, handling debriefing
    set_paused(true)
    # Signal up that we're done
    emit_signal("level_ended", outcome)


func exit() -> void:
    # Cleans up the scene, removing it from the tree
    queue_free()


func get_spawn_points(players: Dictionary):
    # Create a dictionary with peer id and respective spawn points, could be improved by randomizing.
    var spawn_points = {}
    var spawn_point_idx = 0
    for p in players:
        spawn_points[p] = spawn_point_idx
        spawn_point_idx += 1
    return spawn_points


remotesync func despawn_player(player_id: int) -> void:
    if $Players.has_node(str(player_id)):
        $Players.get_node(str(player_id)).queue_free()


func remove_blockable_shot(shot: Projectile) -> void:
    for enemy in $Navigation/Enemies.get_children():
        enemy.remove_blockable_shot(shot.get_name())
