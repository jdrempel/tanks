extends Projectile


func initialize(master_id: int, spawn_time: int):
    set_name("R_%d_%d" % [master_id, spawn_time])
    velocity = -transform.basis.z * move_speed
    velocity.y = 0
    $Particles.emitting = true
