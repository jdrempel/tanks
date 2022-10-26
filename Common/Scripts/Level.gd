extends Node

class_name Level

const NODE_NAME = "Level"

var title: String
var scene: PackedScene
var world: Node

var timer_running := false
var wall_time := 0.0

signal level_loaded()
signal level_ended(outcome)


func _init(_title: String, scene_name: String) -> void:
    self.title = _title
    self.scene = load("res://Scenes/Levels/" + scene_name)


func _process(delta: float) -> void:
    if timer_running:
        wall_time += delta


func get_wall_time() -> float:
    return wall_time


func _ready() -> void:
    connect("level_loaded", $"/root/Lobby", "_on_start_briefing")
    connect("level_ended", $"/root/Lobby", "_on_start_debriefing")


func enter(players: Dictionary) -> void:
    var root = get_tree().get_root()
    if root.has_node(NODE_NAME):
        root.remove_child(root.get_node(NODE_NAME))
    # Instantiates the scene and places it in the tree
    world = scene.instance()
    world.name = NODE_NAME
    root.add_child(world)

    var ordnance_root = Spatial.new()
    ordnance_root.set_name("Ordnance")
    world.add_child(ordnance_root)

    for enemy in world.get_node("Navigation/Enemies").get_children():
        enemy.set_network_master(1)  # server controls all enemies

    var player_scene = load("res://Entities/Players/Player.tscn")

    var spawn_points = get_spawn_points(players)
    for p_id in spawn_points:
        var spawn_pos = world.get_node("SpawnPoints/" + str(spawn_points[p_id])).global_transform
        var player = player_scene.instance()
        player.set_name(str(p_id)) # Use unique ID as node name.
        player.global_transform = spawn_pos
        player.set_network_master(p_id) # set unique id as master.

        world.get_node("Players").add_child(player)

    emit_signal("level_loaded")
    timer_running = true
    yield(GameState, "all_players_ready")
    start()


func start() -> void:
    # Fires after entry and all players loaded
    yield(self, "tree_entered")
    timer_running = true


# TODO sync this
func end(outcome: int) -> void:
    # Fires after all players or all enemies destroyed, handling debriefing
    timer_running = false
    # TODO just freeze ordnance (i.e. disable their physics processes)
    for ordnance in world.get_node("Ordnance").get_children():
        if ordnance is CPUParticles:
            ordnance.emitting = false
        elif ordnance is Projectile:
            ordnance.set_paused(true)
    # Signal up that we're done
    emit_signal("level_ended", outcome)


func exit() -> void:
    # Cleans up the scene, removing it from the tree
    get_tree().get_root().remove_child(world)
    world.call_deferred("free")


func get_spawn_points(players: Dictionary):
    # Create a dictionary with peer id and respective spawn points, could be improved by randomizing.
    var spawn_points = {}
    spawn_points[1] = 0 # Server in spawn point 0.
    var spawn_point_idx = 1
    for p in players:
        spawn_points[p] = spawn_point_idx
        spawn_point_idx += 1
    return spawn_points


remotesync func despawn_player(player_id: int) -> void:
    print("Despawn player %d" % player_id)
    if world.get_node("Players").has_node(str(player_id)):
        world.get_node("Players").get_node(str(player_id)).queue_free()
