extends Node

const NODE_NAME = "Level"

var remote_loaded = false

var ordnance_root: Node

var paused = false
var timer_running := false
var wall_time := 0.0

signal pause_pressed()
signal level_loaded()
signal level_ended(outcome)
signal debrief_over()


func _process(delta: float) -> void:
    if timer_running:
        wall_time += delta


func toggle_pause(val: bool) -> bool:
    # Return value indicates whether the pause menu can/should be shown
    # NOT whether the game was paused (the two don't necessarily go together)
    if $Briefing.visible or $Debriefing.visible:
        return false
    if val:
        $HUD.hide()
    else:
        $HUD.show()
    if Multiplayer.players.size() > 1:
        return true
    set_paused(val)
    return true



func get_wall_time() -> float:
    return wall_time


func _ready() -> void:
    connect("level_ended", self, "_on_start_debriefing")

    GameState.connect("all_players_loaded", self, "start")


func set_paused(val: bool) -> void:
    paused = val
    timer_running = not val
    for ordnance in ordnance_root.get_children():
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


func enter(players: Dictionary, checkpoint: bool) -> void:
    ordnance_root = Spatial.new()
    ordnance_root.set_name("Ordnance")
    get_node("Navigation/NavigationMeshInstance").add_child(ordnance_root)

    var tracks_root = Spatial.new()
    tracks_root.set_name("Tracks")
    add_child(tracks_root)

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
        player.connect("destroyed", GameState, "add_player_death")
        player.setup_tank_color(p_id)

        $Players.add_child(player)

    if checkpoint:
        $Briefing/Checkpoint.show()

    set_paused(true)
    emit_signal("level_loaded")


func start() -> void:
    # Fires after entry and all players loaded
    if not is_inside_tree():
        yield(self, "tree_entered")
    _on_start_briefing()


func _on_enemy_destroyed():
    var enemies_count = get_node("Navigation/Enemies").get_child_count()
    $HUD/Banner/EnemyCounter.text = "x %d" % enemies_count
    if enemies_count == 0 and get_tree().is_network_server():
        GameState.call_deferred("rpc", "win_level")


func _on_player_destroyed():
    var players_count = get_node("Players").get_child_count()
    if players_count == 0 and get_tree().is_network_server():
        GameState.call_deferred("rpc", "lose_level")


func _on_start_briefing():
    $Briefing/Title.text = GameState.current_level_data.name
    $Briefing/EnemyCount.text = \
        "Enemy Tanks: %d" % get_node("Navigation/Enemies").get_child_count()
    $Briefing.show()
    get_tree().create_timer(Globals.BRIEF_TIME).connect("timeout", self, "_on_end_briefing")
    set_paused(true)


func _on_end_briefing():
    $Briefing.hide()
    $HUD/Banner/MissionLabel.text = GameState.current_level_data.name
    $HUD/Banner/EnemyCounter.text = "x %d" % get_node("Navigation/Enemies").get_child_count()
    $HUD.show()
    set_paused(false)


func _on_start_debriefing(outcome: int):
    match outcome:
        Globals.Outcome.Loss:
            $Debriefing/Title.text = "Mission Failed"
        Globals.Outcome.Win:
            $Debriefing/Title.text = "Mission Cleared"
        _:
            $Debriefing/Title.text = "Something went wrong"
            _on_end_debriefing()
            return
    $Debriefing/Time.text = "Time: %4.1f s" % get_wall_time()
    $Debriefing.show()
    $HUD.hide()
    get_tree().create_timer(Globals.DEBRIEF_TIME).connect("timeout", self, "_on_end_debriefing")
    yield(get_tree().create_timer(Globals.DEBRIEF_TIME-Globals.FADE_TIME), "timeout")

    var black = preload("res://Scenes/UI/FadeBlack.tscn").instance()
    add_child(black)
    black.fade_to_black()


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


func rebake_navigation() -> void:
    print("rebaking")
    get_node("Navigation/NavigationMeshInstance").bake_navigation_mesh(true)
    for enemy_node in get_node("Navigation/Enemies").get_children():
        enemy_node.refresh_navigation()
