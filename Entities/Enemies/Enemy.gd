class_name Enemy
extends AbstractTank

var aim_location: Vector3
var aim_jitter_vector: Vector3

export var ai_dodge_skill := 0
export var ai_ignore_bullet_chance := 0.5
export var ai_aim_accuracy := 0.95
export var ai_lead_target_shots := false
export var ai_bounce_wall_shots := false
export var ai_search_time := 5.0
export var ai_engage_time := 1.0
export var ai_flee_time := 3.0

onready var nav = find_parent("Navigation")
var ai_path = []
var ai_path_node = 0
var ai_world_destination: Vector3

var ai_shots_to_block = {}
var ai_shot_block_target = null

export var ai_acquire_target_radius := 15.0  # meters
export var ai_target_lock_sticky_factor := 1.5  # x multiplier

var ai_target: Player

onready var turret_root: Spatial = $Body/TurretRoot

export(PackedScene) var death_explosion


func _ready():
    randomize()
    connect("tree_exited", GameState, "_on_enemy_destroyed")


func _post_init():
    assert($WeaponController.has_active_primary())
    ordnance_speed = $WeaponController.primary_ord_speed


remotesync func destroy():
    emit_signal("destroyed")
    var explosion = death_explosion.instance()
    get_parent().get_parent().add_child(explosion)
    explosion.global_transform.origin = self.global_transform.origin
    for child in explosion.get_children():
        if not (child is CPUParticles):
            continue
        child.emitting = true
    Globals.camera.add_trauma(60)
    AudioManager.play_sound($DestroySound)
    queue_free()


func start_move_to(target_pos):
    ai_path = nav.get_simple_path(global_transform.origin, target_pos, false)
    ai_path_node = 0


# AI Stuff

func get_random_aim_location() -> void:
    turret_root.rpc_unreliable("set_look_location", Vector3(rand_range(-11, 11), 0, rand_range(-8, 8)))


func get_shot_block_aim_location() -> void:
    var soonest_arriving_shot = null
    var soonest_arrival_time = INF
    for shot_name in ai_shots_to_block.keys():
        if ai_shots_to_block[shot_name].arrival_time < soonest_arrival_time:
            soonest_arrival_time = ai_shots_to_block[shot_name].arrival_time
            soonest_arriving_shot = ai_shots_to_block[shot_name].shot
    if is_instance_valid(soonest_arriving_shot):
        aim_location = soonest_arriving_shot.global_transform.origin
        ai_shot_block_target = soonest_arriving_shot


func can_block_shot() -> bool:
    if not is_instance_valid(ai_shot_block_target):
        return false
    if not $WeaponController.active_primary.can_fire():
        return false
    var anti_look_vector = turret_root.global_transform.basis.z.normalized()
    if anti_look_vector.dot(ai_shot_block_target.velocity.normalized()) > 0.99:
        return true
    return false


func get_target_aim_location():
    if not is_instance_valid(ai_target):
        return

    if not ai_lead_target_shots:
        aim_location = ai_target.global_transform.origin
        return

    var target_velocity: Vector3 = ai_target.velocity
    if target_velocity.length() == 0:
        aim_location = ai_target.global_transform.origin
        return

    var ordnance_velocity = $Body/TurretRoot/FirePointCannon.global_transform.basis.z * ordnance_speed

    var to_target = ai_target.global_transform.origin - global_transform.origin

    var a = target_velocity.dot(target_velocity) - ordnance_speed * ordnance_speed
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
        aim_location = ai_target.global_transform.origin + target_velocity * t + aim_jitter_vector


func is_target_in_sight() -> bool:
    var world = get_world()
    if world == null:
        return false
    var space = world.direct_space_state
    var result = space.intersect_ray(
        $Body/TurretRoot/FirePointCannon.global_transform.origin,
        ai_target.global_transform.origin
    )
    return result["collider"] == ai_target


func is_target_acquired() -> bool:
    var aiming_vector = $Body/TurretRoot/FirePointCannon.global_transform.basis.z.normalized()
    var vector_to_target = (aim_location - global_transform.origin).normalized()
    return aiming_vector.dot(-vector_to_target) > (5 + ai_aim_accuracy) / 6


func add_aim_jitter():
    aim_jitter_vector = Vector3(rand_range(-1, 1), 0, rand_range(-1, 1))


func find_target_player():
    var players_node = GameState.current_level.get_node("Players")
    var player_distances = {}
    for player_node in players_node.get_children():
        player_distances[player_node.get_name()] = (player_node.global_translation - global_translation).length()
    var closest_player = null
    var closest_distance = INF
    for player_name in player_distances.keys():
        if player_distances[player_name] < closest_distance and \
                player_distances[player_name] <= ai_acquire_target_radius:
            closest_player = players_node.get_node(player_name)
            closest_distance = player_distances[player_name]
    return closest_player


func keep_target_player():
    if not is_instance_valid(ai_target):
        return false
    var vector_to_target = ai_target.global_transform.origin - global_transform.origin
    var distance_to_target = vector_to_target.length()
    var space = get_world().direct_space_state
    var result = space.intersect_ray(
        $Body/TurretRoot/FirePointCannon.global_transform.origin,
        ai_target.global_transform.origin
    )
    if result.empty():
        return false
    return (
        is_instance_valid(ai_target) and (
            (
                result["collider"] == ai_target
                and distance_to_target <= ai_acquire_target_radius * ai_target_lock_sticky_factor
            )
            or distance_to_target <= ai_acquire_target_radius
        )
    )


func get_new_world_destination():
    var rand_point = Vector3(rand_range(-11, 11), 0, rand_range(-8, 8))
    ai_world_destination = nav.get_closest_point(rand_point)


func set_invisible(val: bool) -> void:
    $Body.set_visible(not val)


func _process(delta):
    if not is_network_master():
        # Player being controlled by remote source
        global_transform.origin = p_origin
        global_transform.basis = p_basis
        velocity = p_velocity
        return

    if not ai_shots_to_block.empty():
        for potential_shot_name in ai_shots_to_block.keys():
            var potential_shot = ai_shots_to_block[potential_shot_name].shot
            if not is_instance_valid(potential_shot):
                continue
            var vector_from_shot_to_here = turret_root.global_transform.origin - \
                potential_shot.global_transform.origin
            if vector_from_shot_to_here.normalized().dot(potential_shot.velocity.normalized()) < 0:
                ai_shots_to_block.erase(potential_shot_name)

    var target_direction: Vector3
    if ai_path_node < ai_path.size():
        target_direction = (ai_path[ai_path_node] - global_transform.origin).normalized()
        if (ai_path[ai_path_node] - global_transform.origin).length() < 0.01 * move_speed:
            ai_path_node += 1
        else:
            if target_direction != last_target_direction:
                set_target_location(target_direction)
            var vectors = rotate_body(delta, target_direction)
            var facing_vector = vectors[0]
            var opposing_vector = vectors[1]
            if facing_vector.dot(target_direction) > 0.999 or opposing_vector.dot(target_direction) > 0.999:
                velocity = move_and_slide(move_speed * target_direction, Vector3.UP)

        last_target_direction = target_direction
    rpc_unreliable("update_pvr", global_transform.origin, velocity, global_transform.basis)


func remove_blockable_shot(shot_name: String) -> void:
    ai_shots_to_block.erase(shot_name)


func _on_ShotDetector_area_entered(area: Area) -> void:
    if not is_network_master():
        return
    var shot = area.get_parent()
    if not shot is Projectile:
        return
    var roll_to_pay_attention = randf()
    if roll_to_pay_attention < ai_ignore_bullet_chance:
        return
    var vector_from_shot_to_here = turret_root.global_transform.origin - shot.global_transform.origin
    if vector_from_shot_to_here.normalized().dot(shot.velocity.normalized()) > 0.85:
        var distance_to_shot = vector_from_shot_to_here.length()
        var time_to_arrival = distance_to_shot / shot.move_speed * 1000
        ai_shots_to_block[shot.get_name()] = {
            "arrival_time": OS.get_system_time_msecs() + time_to_arrival,
            "shot": shot
           }


func _on_ShotDetector_area_exited(area: Area) -> void:
    if not is_network_master():
        return
    var shot = area.get_parent()
    if not shot is Projectile:
        return
    ai_shots_to_block.erase(shot.get_name())
