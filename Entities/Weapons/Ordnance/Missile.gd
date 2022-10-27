extends Projectile


func initialize(master_id: int, spawn_time: int):
    set_name("M_%d_%d" % [master_id, spawn_time])
    velocity = -transform.basis.z * move_speed
    velocity.y = 0


func bounce(pre_velocity: Vector3, collision: KinematicCollision) -> void:
    velocity = pre_velocity.bounce(collision.normal)
    look_at(transform.origin + velocity, Vector3.UP)
    var bounce_pitch = 1 + 0.3 * bounces_remaining
    bounces_remaining -= 1
    AudioManager.play_sound($BounceSound, bounce_pitch)
