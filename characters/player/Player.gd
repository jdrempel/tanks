extends KinematicBody

export var move_speed := 1.5
export var turn_speed = 0.8  # rad/s

var velocity := Vector3.ZERO

var target_location: Vector3
var last_target_direction: Vector3
var target_rotation: Basis
var opposite_rotation: Basis
var rotation_lerp := 0.0

# Network stuff
puppet var p_origin := Vector3.ZERO
puppet var p_basis := Basis.IDENTITY
puppet var p_velocity := Vector3.ZERO


signal destroyed()


func _ready():
	GameState.rpc("add_living_player")
	connect("destroyed", GameState, "_player_destroyed")
	
	if get_network_master() != 1:
		var material_p2 = load("res://materials/player2.tres") as Material
		$Body.material_override = material_p2
		$Body/TurretRoot/Turret.material_override = material_p2


func set_player_name(name: String):
	pass


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
	GameState.remove_living_player()
	emit_signal("destroyed")
	queue_free()


func get_movement_vector():
	var target_direction := Vector3.ZERO
	
	if Input.is_action_pressed("move_up"):
		target_direction.z -= 1
	if Input.is_action_pressed("move_down"):
		target_direction.z += 1
	if Input.is_action_pressed("move_left"):
		target_direction.x -= 1
	if Input.is_action_pressed("move_right"):
		target_direction.x += 1
	
	if target_direction.length():
		return target_direction.normalized()
	return target_direction


remote func update_pvr(pos, vel, rot):
	p_origin = pos
	p_basis = rot
	p_velocity = vel


func _physics_process(delta):
	if not is_network_master():
		# Player being controlled by remote source
		global_transform.origin = p_origin
		global_transform.basis = p_basis
		velocity = p_velocity
		return
	
	# Player being controlled by local client
	var target_direction = get_movement_vector()
	if target_direction != Vector3.ZERO:
		if target_direction != last_target_direction:
			set_target_location(target_direction)
		var vectors = rotate_player(delta, target_direction)
		var facing_vector = vectors[0]
		var opposing_vector = vectors[1]
		if facing_vector.dot(target_direction) > 0.999 or opposing_vector.dot(target_direction) > 0.999:
			velocity = move_and_slide(move_speed * target_direction, Vector3.UP)
	else:
		velocity = Vector3.ZERO
	
	last_target_direction = target_direction
	rpc_unreliable("update_pvr", global_transform.origin, velocity, global_transform.basis)
