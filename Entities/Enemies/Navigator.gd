extends Node


var enemy: Spatial

var nav: Navigation
var path := []
var path_node: int

var destination: Vector3


func _ready() -> void:
    nav = GameState.current_level.get_node("Navigation")


func initialize(_enemy) -> void:
    enemy = _enemy


func start_move() -> void:
    path = nav.get_simple_path(enemy.global_transform.origin, destination, false)
    path_node = 0


func set_destination(location: Vector3) -> void:
    destination = nav.get_closest_point(location)


func set_random_world_destination() -> void:
    var rand_point = Vector3(rand_range(-11, 11), 0, rand_range(-8, 8))
    destination = nav.get_closest_point(rand_point)


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
