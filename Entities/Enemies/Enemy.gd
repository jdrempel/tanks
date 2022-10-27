class_name Enemy
extends AbstractTank

var aim_location: Vector3
var aim_jitter_vector: Vector3

export var ai_search_time := 5.0
export var ai_engage_time := 1.0
export var ai_flee_time := 3.0

export var ai_aim_accuracy := 0.95
export var ai_aim_jitter := 1.5
export var ai_primary_cooldown_override := -1.0
export var ai_secondary_cooldown_override := -1.0

onready var nav = find_parent("Navigation")
var ai_path = []
var ai_path_node = 0
var ai_world_destination: Vector3

var ai_max_courage := 1.0
export var ai_courage_regen_rate := 0.1  # per second
export var ai_courage_drain_multiplier := 1.0

export var ai_acquire_target_radius := 5.0  # meters
export var ai_target_lock_sticky_factor := 1.5  # x multiplier

var ai_target: Player
onready var turret_root: Spatial = $Body/TurretRoot

export(PackedScene) var death_explosion


func _ready():
    randomize()

    GameState.add_living_enemy()
    # GameState.rpc("add_living_enemy")
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

func get_random_aim_location():
    turret_root.rpc_unreliable("set_look_location", Vector3(rand_range(-11, 11), 0, rand_range(-8, 8)))


func get_target_aim_location():
    if not is_instance_valid(ai_target):
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
    return aiming_vector.dot(-vector_to_target) > ai_aim_accuracy


func add_aim_jitter():
    aim_jitter_vector = Vector3(
        rand_range(-ai_aim_jitter, ai_aim_jitter),
        0,
        rand_range(-ai_aim_jitter, ai_aim_jitter)
    )


func find_target_player():
    var players_node = get_node("../../../Players")
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


func _process(delta):
    if not is_network_master():
        # Player being controlled by remote source
        global_transform.origin = p_origin
        global_transform.basis = p_basis
        velocity = p_velocity
        return

    var target_direction: Vector3
    if ai_path_node < ai_path.size():
        target_direction = (ai_path[ai_path_node] - global_transform.origin).normalized()
        if (ai_path[ai_path_node] - global_transform.origin).length() < 0.01:
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
