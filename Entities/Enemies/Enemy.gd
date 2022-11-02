class_name Enemy
extends AbstractTank

const RADIUS := 0.5

export var ai_dodge_skill := 0
export var ai_ignore_bullet_chance := 0.5
export var ai_aim_accuracy := 0.95
export var ai_lead_target_shots := false
export var ai_bounce_wall_shots := false
export var ai_search_time := 5.0
export var ai_engage_time := 1.0
export var ai_flee_time := 3.0
export var ai_acquire_target_radius := 15.0  # meters

onready var turret_root: Spatial = $Body/TurretRoot
onready var navigator = $Navigator
onready var targeting = $Targeting

export(PackedScene) var death_explosion


func _ready():
    randomize()
    connect("tree_exited", GameState, "_on_enemy_destroyed")

    navigator.initialize(self)
    targeting.initialize(self)


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


# AI Stuff

func can_block_shot() -> bool:
    if not is_instance_valid(targeting.shot_block_target):
        return false
    if not $WeaponController.active_primary.can_fire():
        return false
    var anti_look_vector = turret_root.global_transform.basis.z.normalized()
    if anti_look_vector.dot(targeting.shot_block_target.velocity.normalized()) > 0.99:
        return true
    return false


func set_invisible(val: bool) -> void:
    $Body.set_visible(not val)


func _physics_process(delta):
    if not is_network_master():
        # Player being controlled by remote source
        global_transform.origin = p_origin
        global_transform.basis = p_basis
        velocity = p_velocity
        return

    if paused:
        return

    if not targeting.shots_to_block.empty():
        for potential_shot_name in targeting.shots_to_block.keys():
            var potential_shot = targeting.shots_to_block[potential_shot_name].shot
            if not is_instance_valid(potential_shot):
                continue
            var vector_from_shot_to_here = turret_root.global_transform.origin - \
                potential_shot.global_transform.origin
            if vector_from_shot_to_here.normalized().dot(potential_shot.velocity.normalized()) < 0:
                targeting.shots_to_block.erase(potential_shot_name)

    if $WeaponController.has_active_secondary() and $WeaponController.has_node("MineLayer"):
        if randf() > 0.96:
            $WeaponController.rpc("fire_secondary", OS.get_system_time_msecs())

    var target_direction = navigator.get_target_direction()
    if not navigator.is_at_path_node():
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
    targeting.shots_to_block.erase(shot_name)


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
        targeting.shots_to_block[shot.get_name()] = {
            "arrival_time": OS.get_system_time_msecs() + time_to_arrival,
            "shot": shot
           }


func _on_ShotDetector_area_exited(area: Area) -> void:
    if not is_network_master():
        return
    var shot = area.get_parent()
    if not shot is Projectile:
        return
    targeting.shots_to_block.erase(shot.get_name())
