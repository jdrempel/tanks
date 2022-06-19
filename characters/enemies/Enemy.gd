extends KinematicBody

export var move_speed := 1.5
export var turn_speed := 0.8  # rad/s

# Temporary
onready var player1 = get_node("/root/Main/Player1")
onready var player2 = get_node("/root/Main/Player2")

var velocity := Vector3.ZERO

var target_location: Vector3
var last_target_direction: Vector3
var target_rotation: Basis
var opposite_rotation: Basis
var rotation_lerp := 0.0

enum AiState { SEARCHING, ENGAGING, FLEEING }
var ai_state = AiState.SEARCHING
export var ai_search_time := 5.0
export var ai_engage_time := 3.0
export var ai_flee_time := 3.0

onready var nav = find_parent("Navigation")
var ai_path = []
var ai_path_node = 0

var ai_max_courage := 1.0
export var ai_courage_regen_rate := 0.1  # per second
export var ai_courage_drain_multiplier := 1.0

export var ai_sight_radius := 5.0  # meters

var ai_target


func _ready():
	enter_searching()


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
	ai_path = nav.get_simple_path(global_transform.origin, target_pos, false)
	ai_path_node = 0


# AI Stuff

func enter_searching():
	ai_state = AiState.SEARCHING
	print("searching")
	$SearchTimer.start(ai_search_time)
	# pick random location within search radius


func enter_engaging():
	ai_state = AiState.ENGAGING
	print("engaging")
	$EngageTimer.start(ai_engage_time)
	# pick random location with LOS to player (or keep current target)


func enter_fleeing():
	ai_state = AiState.FLEEING
	print("fleeing")
	$FleeTimer.start(ai_flee_time)
	# pick random location with no LOS to player (prefer further away than current)


func leave_searching():
	$SearchTimer.stop()


func leave_engaging():
	$EngageTimer.stop()


func leave_fleeing():
	$FleeTimer.stop()


func is_target_acquired() -> bool:
	var space = get_world().direct_space_state
	var result = space.intersect_ray(
		$Body/TurretRoot/FirePointCannon.global_transform.origin,
		ai_target.global_transform.origin
	)
	return result["collider"].is_in_group("tanks")


func find_target_player():
	var distance_to_player1
	var distance_to_player2
	player1 = get_node("/root/Main/Player1")
	player2 = get_node("/root/Main/Player2")
	if player1 != null:
		var player1_origin = player1.global_transform.origin
		var vector_to_player1 = player1_origin - global_transform.origin
		distance_to_player1 = vector_to_player1.length()
	if player2 != null:
		var player2_origin = player2.global_transform.origin
		var vector_to_player2 = player2_origin - global_transform.origin
		distance_to_player2 = vector_to_player2.length()
	if player1 != null:
		if distance_to_player1 <= ai_sight_radius:
			return player1
	else:
		return null


func process_ai_state():
	match ai_state:
		AiState.SEARCHING:
			ai_target = find_target_player()
			if ai_target != null:
				leave_searching()
				enter_engaging()
		AiState.ENGAGING:
			ai_target = find_target_player()
			if ai_target == null:
				leave_engaging()
				enter_searching()
		AiState.FLEEING:
			pass
		_:
			print("ai_state: \"this shall not be my fate\"")
			get_tree().quit()


func _process(delta):
	process_ai_state()
	var target_direction: Vector3
	if ai_path_node < ai_path.size():
		target_direction = (ai_path[ai_path_node] - global_transform.origin).normalized()
		if (ai_path[ai_path_node] - global_transform.origin).length() < 0.01:
			ai_path_node += 1
		else:
			if target_direction != last_target_direction:
				set_target_location(target_direction)
			var vectors = rotate_player(delta, target_direction)
			var facing_vector = vectors[0]
			var opposing_vector = vectors[1]
			if facing_vector.dot(target_direction) > 0.999 or opposing_vector.dot(target_direction) > 0.999:
				velocity = move_and_slide(move_speed * target_direction, Vector3.UP)
	
		last_target_direction = target_direction


func _on_SearchTimer_timeout():
	pass # Replace with function body.


func _on_EngageTimer_timeout():
	if ai_target != null:
		if is_target_acquired():
			$WeaponController.active_primary._fire()
		else:
			move_to(ai_target.global_transform.origin)


func _on_FleeTimer_timeout():
	pass # Replace with function body.
