extends KinematicBody

export var move_speed := 1.5
export var turn_speed = 0.8  # rad/s

var path = []
var path_node = 0
onready var nav = find_parent("Navigation")
# Temporary
onready var player = get_node("/root/Main/Player")

var velocity := Vector3.ZERO

var target_location: Vector3
var last_target_direction: Vector3
var target_rotation: Basis
var opposite_rotation: Basis
var rotation_lerp := 0.0


func set_target_location(new_target: Vector3):
	target_location = new_target * 1000 + global_transform.origin
	rotation_lerp = 0


func rotate_player(delta, target_direction):
	target_rotation = transform.looking_at(target_location, Vector3.UP).basis
	var target_quat = target_rotation.get_rotation_quat()
	var angle_to_target = transform.basis.get_rotation_quat().angle_to(target_quat)
	opposite_rotation = target_rotation.rotated(Vector3.UP, PI)
	var opposite_quat = opposite_rotation.get_rotation_quat()
	var angle_to_opposite = transform.basis.get_rotation_quat().angle_to(opposite_quat)
	var pointing_vector: Vector3
	if angle_to_target > angle_to_opposite:
		target_rotation = opposite_rotation
	var facing_vector := -transform.basis.z.normalized()
	var opposing_vector := transform.basis.z.normalized()
	if facing_vector.dot(target_direction) < 1 and opposing_vector.dot(target_direction) < 1:
		if rotation_lerp < 1:
			rotation_lerp += delta * turn_speed
		elif rotation_lerp > 1:
			rotation_lerp = 1
		transform.basis = transform.basis.slerp(target_rotation, rotation_lerp).orthonormalized()
	
	return [facing_vector, opposing_vector]


func destroy():
	queue_free()


func move_to(target_pos):
	path = nav.get_simple_path(global_transform.origin, target_pos, false)
	path_node = 0


func _process(delta):
	var target_direction: Vector3
	if path_node < path.size():
		target_direction = (path[path_node] - global_transform.origin).normalized()
		if (path[path_node] - global_transform.origin).length() < 0.01:
			path_node += 1
		else:
			if target_direction != last_target_direction:
				set_target_location(target_direction)
			var vectors = rotate_player(delta, target_direction)
			var facing_vector = vectors[0]
			var opposing_vector = vectors[1]
			if facing_vector.dot(target_direction) > 0.999 or opposing_vector.dot(target_direction) > 0.999:
				velocity = move_and_slide(move_speed * target_direction, Vector3.UP)
	
		last_target_direction = target_direction


func _on_PathTimer_timeout():
	if player != null:
		move_to(player.global_transform.origin)
