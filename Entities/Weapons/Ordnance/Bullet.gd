extends Projectile


func initialize(master_id: int, spawn_time: int):
    set_network_master(master_id)
    set_name("B_%d_%d" % [master_id, spawn_time])
    p_origin = global_transform.origin
    p_basis = global_transform.basis
    velocity = -transform.basis.z * move_speed
    velocity.y = 0
    p_velocity = velocity
    $Particles.emitting = true
