extends Node


const TARGET_LOCK_STICKY_FACTOR = 1.5

var enemy: Spatial

var aim_location: Vector3
var aim_jitter: Vector3

var player_target: Player

var shots_to_block := {}
var shot_block_target


func initialize(_enemy) -> void:
    enemy = _enemy


func set_random_aim_location() -> void:
    var y = Vector3(rand_range(-11, 11), 0, rand_range(-8, 8))
    enemy.turret_root.rpc_unreliable("set_look_location", y)


func get_shot_block_aim_location() -> void:
    var soonest_arriving_shot = null
    var soonest_arrival_time = INF
    for shot_name in shots_to_block.keys():
        if shots_to_block[shot_name].arrival_time < soonest_arrival_time:
            soonest_arrival_time = shots_to_block[shot_name].arrival_time
            soonest_arriving_shot = shots_to_block[shot_name].shot
    if is_instance_valid(soonest_arriving_shot):
        aim_location = soonest_arriving_shot.global_transform.origin
        shot_block_target = soonest_arriving_shot


func remove_blockable_shot(shot: Projectile) -> void:
    shots_to_block.erase(shot.get_name())
    if shot_block_target == shot:
        shot_block_target = null


func get_target_aim_location():
    if not is_instance_valid(player_target):
        return

    if not enemy.ai_lead_target_shots:
        aim_location = player_target.global_transform.origin
        return

    var target_velocity: Vector3 = player_target.velocity
    if target_velocity.length() == 0:
        aim_location = player_target.global_transform.origin
        return

    var ordnance_velocity = enemy.turret_root.get_node("FirePointCannon").global_transform.basis.z \
        * enemy.ordnance_speed

    var to_target = player_target.global_transform.origin - enemy.global_transform.origin

    var a = target_velocity.dot(target_velocity) - enemy.ordnance_speed * enemy.ordnance_speed
    var b = 2 * target_velocity.dot(to_target)
    var c = to_target.dot(to_target)

    var p = -b / (2 * a)
    var q = (sqrt((b*b) - 4*a*c) as float) / (2 * a)

    var t1 = p - q
    var t2 = p + q
    var t

    if (t1 > t2 and t2 > 0):
        t = t2
    else:
        t = t1

    if t > 0:
        aim_location = player_target.global_transform.origin + target_velocity * t + aim_jitter


func is_target_in_sight() -> bool:
    var world = enemy.get_world()
    if world == null:
        return false
    var space = world.direct_space_state
    var result = space.intersect_ray(
        enemy.turret_root.get_node("FirePointCannon").global_transform.origin,
        player_target.global_transform.origin
    )
    return result["collider"] == player_target


func is_target_acquired() -> bool:
    var aiming_vector = enemy.turret_root.get_node("FirePointCannon").global_transform.basis.z.normalized()
    var vector_to_target = (aim_location - enemy.global_transform.origin).normalized()
    return aiming_vector.dot(-vector_to_target) > (5 + enemy.ai_aim_accuracy) / 6


func add_aim_jitter():
    aim_jitter = Vector3(rand_range(-1, 1), 0, rand_range(-1, 1))


func find_target_player():
    var players_node = GameState.current_level.get_node("Players")
    var player_distances = {}
    for player_node in players_node.get_children():
        player_distances[player_node.get_name()] = (player_node.global_translation - enemy.global_translation).length()
    var closest_player = null
    var closest_distance = INF
    for player_name in player_distances.keys():
        if player_distances[player_name] < closest_distance and \
                player_distances[player_name] <= enemy.ai_acquire_target_radius:
            closest_player = players_node.get_node(player_name)
            closest_distance = player_distances[player_name]
    return closest_player


func keep_target_player():
    if not is_instance_valid(player_target):
        return false
    var vector_to_target = player_target.global_transform.origin - enemy.global_transform.origin
    var distance_to_target = vector_to_target.length()
    var space = enemy.get_world().direct_space_state
    var result = space.intersect_ray(
        enemy.turret_root.get_node("FirePointCannon").global_transform.origin,
        player_target.global_transform.origin
    )
    if distance_to_target <= enemy.ai_acquire_target_radius:
        return true
    elif (
        result.empty() or
        result.collider != player_target or
        not is_instance_valid(player_target) or
        distance_to_target > enemy.ai_acquire_target_radius * TARGET_LOCK_STICKY_FACTOR
    ):
        return false
    else:
        return true


func is_location_safe_from_shots(offset: Vector3, shot_keys: Array) -> bool:
    var space = enemy.get_world().direct_space_state
    for key in shot_keys:
        var shot_to_location_vector = enemy.global_translation + offset - shots_to_block[key].shot.global_translation
        var shot_location = shots_to_block[key].shot.global_translation
        var shot_projection = shots_to_block[key].shot.velocity.normalized()
        var shot_path_to_location_distance = shot_projection.cross(shot_to_location_vector).length()
        print(shot_path_to_location_distance)
        if shot_path_to_location_distance < enemy.RADIUS:
            return false
    return true


func get_safe_dodge_location() -> Vector3:
    if enemy.ai_dodge_skill == 0:
        return enemy.global_transform.origin
    var arrival_times = shots_to_block.keys()
    arrival_times.sort()
    var able_to_dodge_keys = arrival_times.slice(0, enemy.ai_dodge_skill-1)
    var dodge_offset = Vector3.ZERO
    var space = enemy.get_world().direct_space_state
    while not is_location_safe_from_shots(dodge_offset, able_to_dodge_keys):
        dodge_offset = Vector3(enemy.RADIUS * cos(2 * randf() * PI), 0, enemy.RADIUS * cos(2 * randf() * PI))
        prints("Dodge offset: ", dodge_offset)
    return dodge_offset

