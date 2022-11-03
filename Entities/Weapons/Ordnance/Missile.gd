extends Projectile


func initialize(master_id: int, spawn_time: int):
    set_network_master(master_id)
    set_name("M_%d_%d" % [master_id, spawn_time])
    velocity = -transform.basis.z * move_speed
    velocity.y = 0
    $Particles.emitting = true


func bounce(pre_velocity: Vector3, normal: Vector3) -> void:
    velocity = pre_velocity.bounce(normal)
    look_at(transform.origin + velocity, Vector3.UP)
    var bounce_pitch = 1 + 0.3 * bounces_remaining
    bounces_remaining -= 1
    AudioManager.play_sound($BounceSound, bounce_pitch)
