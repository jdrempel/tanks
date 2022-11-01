extends Node


var enemy: Spatial

var nav: Navigation
var path := []
var path_node: int

var destination: Vector3
var dodging = false

# debug
var debug_sphere: MeshInstance


func _ready() -> void:
    nav = GameState.current_level.get_node("Navigation")

    if Globals.DEBUG:
        debug_sphere = MeshInstance.new()
        var sphere_mesh = SphereMesh.new()
        sphere_mesh.height = 0.05
        sphere_mesh.radius = 0.05
        sphere_mesh.radial_segments = 8
        sphere_mesh.rings = 8
        debug_sphere.mesh = sphere_mesh


func _physics_process(delta: float) -> void:
    if Globals.DEBUG:
        debug_sphere.global_translation = destination


func initialize(_enemy) -> void:
    enemy = _enemy
    enemy.add_child(debug_sphere)


func is_dodging() -> bool:
    return dodging


func start_dodge() -> void:
    dodging = true


func end_dodge() -> void:
    dodging = false


func start_move() -> void:
    path = nav.get_simple_path(enemy.global_transform.origin, destination, false)
    path_node = 0


func set_destination(location: Vector3) -> void:
    destination = nav.get_closest_point(location)


func set_random_world_destination() -> void:
    var rand_point = Vector3(rand_range(-11, 11), 0, rand_range(-8, 8))
    destination = nav.get_closest_point(rand_point)


func set_flee_destination() -> void:
    var random_radius = rand_range(0.5, 2.0)
    var resultant = enemy.global_translation
    for player in GameState.current_level.get_node("Players").get_children():
        var vector_from_player = enemy.global_translation - player.global_translation
        var force_direction = vector_from_player.normalized()
        var force_magnitude = 100 / vector_from_player.length_squared()
        resultant += force_magnitude * force_direction
    var random_offset = Globals.random_point_on_circle(resultant, random_radius)
    destination = nav.get_closest_point(random_offset)


func get_target_direction() -> Vector3:
    var target_direction = Vector3.ZERO
    if path_node < path.size():
        target_direction = (path[path_node] - enemy.global_transform.origin).normalized()
        if is_at_path_node():
            set_deferred("path_node", path_node + 1)
    return target_direction


func is_at_path_node() -> bool:
    if path_node >= path.size():
        return true
    return (path[path_node] - enemy.global_transform.origin).length() < 0.01 * enemy.move_speed
