extends Node


var enemy: Spatial

# var nav: Navigation
var agent: NavigationAgent
# var path := []
# var path_node: int

var destination: Vector3
var dodging = false

# debug
var debug_sphere: MeshInstance
var debug_path_meshes = []


func _ready() -> void:
    # nav = GameState.current_level.get_node("Navigation")
    agent = get_parent().get_node("Agent")

    if Globals.DEBUG:
        debug_sphere = MeshInstance.new()
        var sphere_mesh = SphereMesh.new()
        sphere_mesh.height = 0.05
        sphere_mesh.radius = 0.05
        sphere_mesh.radial_segments = 8
        sphere_mesh.rings = 8
        debug_sphere.mesh = sphere_mesh

        for __ in range(30):
            var new_dot = MeshInstance.new()
            var dot_mesh = SphereMesh.new()
            dot_mesh.height = 0.1
            dot_mesh.radius = 0.1
            dot_mesh.radial_segments = 6
            dot_mesh.rings = 6
            new_dot.mesh = dot_mesh
            debug_path_meshes.append(new_dot)


func _physics_process(delta: float) -> void:
    if Globals.DEBUG:
        debug_sphere.global_translation = destination
        update_debug_spheres()


func initialize(_enemy) -> void:
    enemy = _enemy

    agent.path_desired_distance = enemy.move_speed * 0.1
    agent.target_desired_distance = enemy.move_speed * 0.1
    agent.path_max_distance = 2.0
    agent.avoidance_enabled = true
    agent.max_speed = enemy.move_speed

    if Globals.DEBUG:
        enemy.add_child(debug_sphere)
        for dot in debug_path_meshes:
            add_child(dot)


func is_dodging() -> bool:
    return dodging


func start_dodge() -> void:
    dodging = true


func end_dodge() -> void:
    dodging = false


func update_debug_spheres() -> void:
    var path = agent.get_nav_path()
    if path.empty():
        return
    for index in range(debug_path_meshes.size()):
        debug_path_meshes[index].global_transform.origin = path[min(index, path.size()-1)]
    for pt in path:
        if not is_equal_approx(pt.y, 0.2):
            print(pt)


func start_move() -> void:
    agent.set_target_location(destination)
    # path = nav.get_simple_path(enemy.global_transform.origin, destination, false)
    # path_node = 0


func set_destination(location: Vector3) -> void:
    destination = location
    agent.set_target_location(destination)


func set_random_world_destination() -> void:
    var rand_point = Vector3(rand_range(-11, 11), 0, rand_range(-8, 8))
    set_destination(rand_point)


func set_flee_destination() -> void:
    var random_radius = rand_range(0.5, 2.0)
    var resultant = enemy.global_translation
    for player in GameState.current_level.get_node("Players").get_children():
        var vector_from_player = enemy.global_translation - player.global_translation
        var force_direction = vector_from_player.normalized()
        var force_magnitude = 100 / vector_from_player.length_squared()
        resultant += force_magnitude * force_direction
    var random_offset = Globals.random_point_on_circle(resultant, random_radius)
    set_destination(random_offset)


func get_target_direction() -> Vector3:
    var target_direction = Vector3.ZERO
    var next_location = agent.get_next_location()
    target_direction = next_location - enemy.global_transform.origin
    return target_direction.normalized()


func is_at_destination() -> bool:
    return (enemy.global_transform.origin - agent.get_final_location()).length() < \
        0.01 * enemy.move_speed
