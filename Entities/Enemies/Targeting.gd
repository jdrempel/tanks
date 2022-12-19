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
    if not is_instance_valid(player_target):
        return false
    var world = enemy.get_world()
    if world == null:
        return false
    var space = world.direct_space_state
    var result = space.intersect_ray(
        enemy.turret_root.get_node("FirePointCannon").global_transform.origin,
        player_target.global_transform.origin
    )
    if result.empty():
        return false
    return result.collider == player_target


func is_aiming_at_self_or_ally(num_bounces: int) -> bool:
    var world = enemy.get_world()
    if world == null:
        return false
    var space = world.direct_space_state
    var fire_point_origin = enemy.turret_root.get_node("FirePointCannon").global_transform.origin
    var ray_vector = -enemy.turret_root.get_node("FirePointCannon").global_transform.basis.z
    var result = space.intersect_ray(
        fire_point_origin,
        fire_point_origin + 1000 * ray_vector,
        [],
        11  # world, players, enemies
    )
    if not result.empty():
        if result.collider is Enemy:
            return true
        if result.collider is Player:
            return false
        var bounce_origin = result.position
        var bounce_normal = result.normal
        for __ in num_bounces:
            var impact = space.intersect_ray(
                bounce_origin,
                bounce_origin + 1000 * ray_vector.bounce(bounce_normal),
                [],
                11  # world, players, enemies
            )
            if not impact.empty():
                if impact.collider is Enemy:
                    return true
                if impact.collider is Player:
                    return false
                bounce_origin = impact.position
                bounce_normal = impact.normal
    return false


func can_bounce_to_target(num_bounces: int) -> bool:
    var world = enemy.get_world()
    if world == null:
        return false
    var space = world.direct_space_state
    var fire_point_origin = enemy.turret_root.get_node("FirePointCannon").global_transform.origin
    for angle in range(0, 360, 2):
        var ray_vector = Vector3(cos(deg2rad(angle)), 0.0, sin(deg2rad(angle)))
        var result = space.intersect_ray(
            fire_point_origin,
            fire_point_origin + 1000 * ray_vector,
            [],
            8  # world
        )
        if not result.empty():
            var bounce_origin = result.position
            var bounce_normal = result.normal
            for __ in num_bounces:
                var impact = space.intersect_ray(
                    bounce_origin,
                    bounce_origin + 1000 * ray_vector.bounce(bounce_normal),
                    [],
                    9  # world and players
                )
                if not impact.empty():
                    bounce_origin = impact.position
                    bounce_normal = impact.normal
                    if impact.collider is Player and impact.collider == player_target:
                        aim_location = result.position  # the original bounce location
                        return true
    return false


func is_target_acquired() -> bool:
    return abs(enemy.turret_root.get_angle_to_target()) <= \
        deg2rad(20.0 * (1.0 - enemy.ai_aim_accuracy))


func add_aim_jitter():
    aim_jitter = Vector3(rand_range(-1, 1), 0, rand_range(-1, 1))


func find_target_player():
    if not is_instance_valid(GameState.current_level):
        return
    var players_node = GameState.current_level.get_node("Players")
    var space = enemy.get_world().direct_space_state
    var player_distances = {}
    for player_node in players_node.get_children():
        var result = space.intersect_ray(
            enemy.turret_root.get_node("FirePointCannon").global_transform.origin,
            player_node.global_transform.origin,
            [],
            8  # just the world layer
        )
        player_distances[player_node.get_name()] = {
            distance=(player_node.global_translation - enemy.global_translation).length(),
            has_los=result.empty()
        }
    var closest_player = null
    var closest_distance = INF
    var players_with_los = {}
    for player_name in player_distances.keys():
        if player_distances[player_name].has_los:
            players_with_los[player_name] = player_distances[player_name]
    var priority_player_list = {}
    if not players_with_los.empty():
        priority_player_list = players_with_los
    else:
        priority_player_list = player_distances
    for player_name in priority_player_list.keys():
        if priority_player_list[player_name].distance < closest_distance:
            closest_player = players_node.get_node(player_name)
            closest_distance = priority_player_list[player_name].distance
    player_target = closest_player
    return closest_player


func keep_target_player():
    return is_instance_valid(player_target)


func is_location_safe_from_shots(location: Vector3, shot_keys: Array) -> bool:
    var space = enemy.get_world().direct_space_state
    for key in shot_keys:
        var shot_to_location_vector = location - shots_to_block[key].shot.global_translation
        var shot_location = shots_to_block[key].shot.global_translation
        var shot_projection = shots_to_block[key].shot.velocity.normalized()
        var shot_path_to_location_distance = shot_projection.cross(shot_to_location_vector).length()
        if shot_path_to_location_distance < enemy.RADIUS:
            return false
    return true


func get_safe_dodge_location() -> Vector3:
    if enemy.ai_dodge_skill == 0:
        return enemy.global_transform.origin
    var arrival_times = shots_to_block.keys()
    arrival_times.sort()
    var able_to_dodge_keys = arrival_times.slice(0, enemy.ai_dodge_skill-1)
    var dodge_location = enemy.global_translation
    var space = enemy.get_world().direct_space_state
    var attempts = 0
    while not is_location_safe_from_shots(dodge_location, able_to_dodge_keys) and attempts < 10:
        dodge_location = Globals.random_point_on_circle(enemy.global_translation, enemy.RADIUS * 1.1)
        attempts += 1
    return dodge_location

