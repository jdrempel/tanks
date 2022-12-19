extends Projectile


func initialize(master_id: int, spawn_time: int):
    self.master_id = master_id
    set_network_master(MetaManager.player_manager.get_player_network_master(master_id))
    set_name("M_%d_%d" % [master_id, spawn_time])
    player_shot = master_id >= 0
    velocity = -transform.basis.z * move_speed
    velocity.y = 0
    $Particles.emitting = true
    if player_shot and is_network_master():
        emit_signal("player_shot_fired", master_id)


func bounce(pre_velocity: Vector3, normal: Vector3) -> void:
    velocity = pre_velocity.bounce(normal)
    look_at(transform.origin + velocity, Vector3.UP)
    var bounce_pitch = 1 + 0.3 * bounces_remaining
    bounces_remaining -= 1
    AudioManager.play_sound($BounceSound, bounce_pitch)
