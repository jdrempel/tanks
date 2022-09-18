extends Node

class_name Level

const NODE_NAME = "Level"

var title: String
var scene: PackedScene
var world: Node

signal level_loaded()
signal level_ended(outcome)


func _init(_title: String, scene_name: String) -> void:
    self.title = _title
    self.scene = load("res://Scenes/Levels/" + scene_name)


func enter(players: Dictionary) -> void:
    if get_tree().get_root().has_node("Level"):
        print("level: Abort enter(), level already exists")
        return
    # Instantiates the scene and places it in the tree
    world = scene.instance()
    world.name = NODE_NAME
    get_tree().get_root().add_child(world)

    for enemy in world.get_node("Navigation/Enemies").get_children():
        enemy.set_network_master(1)  # server controls all enemies

    var player_scene = load("res://Entities/Players/Player.tscn")

    var spawn_points = get_spawn_points(players)
    for p_id in spawn_points:
        var spawn_pos = world.get_node("SpawnPoints/" + str(spawn_points[p_id])).global_transform
        var player = player_scene.instance()

        var player_num = 1
        if str(p_id) != str(player_num):
            player_num = 2
        player.set_name("Player" + str(player_num)) # Use unique ID as node name.
        player.global_transform = spawn_pos
        player.set_network_master(p_id) # set unique id as master.

        world.get_node("Players").add_child(player)

    emit_signal("level_loaded")
    print("level: loaded!")
    yield(GameState, "all_players_ready")
    print("level: all players ready!")

    start()


func start() -> void:
    # Fires after entry and all players loaded
    print("level: about to start")
    yield(self, "tree_entered")
    print("level: entered tree")
    # Display "briefing" banner
    # Start briefing_timer
    print("level: created briefing timer")
    yield(get_tree().create_timer(3.0), "timeout")
    # Unpause the level node
    # get_tree().set_pause(false)
    print("level: unpaused")
    # Hide "briefing" banner
    # Start setup_timer
    yield(get_tree().create_timer(5.0), "timeout")


# TODO sync this
func end(outcome: int) -> void:
    # Fires after all players or all enemies destroyed, handling debriefing
    # Pause the level node
    # get_tree().set_pause(true)
    print("level: paused")
    # Display score banner
    # Start debriefing timer
    yield(get_tree().create_timer(5.0), "timeout")
    # Hide score banner
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
    prints("level: gsp", spawn_points)
    return spawn_points
