extends KinematicBody

export var move_speed := 1.5
export var turn_speed = 0.8  # rad/s

var velocity := Vector3.ZERO

var target_location: Vector3
var last_target_direction: Vector3
var target_rotation: Basis
var rotation_lerp := 0.0


func set_target_location(new_target: Vector3):
	target_location = new_target + global_transform.origin
	rotation_lerp = 0


func rotate_player(delta):
	if rotation_lerp < 1:
		rotation_lerp += delta * turn_speed
	elif rotation_lerp > 1:
		rotation_lerp = 1
	transform.basis = transform.basis.slerp(target_rotation, rotation_lerp).orthonormalized()


func destroy():
	queue_free()


func _process(delta):
	var target_direction := Vector3.ZERO
	
	if Input.is_action_pressed("move_up"):
		target_direction.z -= 1
	if Input.is_action_pressed("move_down"):
		target_direction.z += 1
	if Input.is_action_pressed("move_left"):
		target_direction.x -= 1
	if Input.is_action_pressed("move_right"):
		target_direction.x += 1
	
	if target_direction != Vector3.ZERO:
		target_direction = target_direction.normalized()
		var distance_to_target_location = (target_location - transform.origin).length()
		if target_direction != last_target_direction or distance_to_target_location < 2 * move_speed * delta:
			set_target_location(target_direction)
		target_rotation = transform.looking_at(target_location, Vector3.UP).basis
		rotate_player(delta)
		var facing_vector := -transform.basis.z.normalized()
		var opposing_vector := transform.basis.z.normalized()
		if facing_vector.dot(target_direction) > 0.99 or opposing_vector.dot(target_direction) > 0.99:
			velocity = move_and_slide(move_speed * target_direction, Vector3.UP)
	
	last_target_direction = target_direction
