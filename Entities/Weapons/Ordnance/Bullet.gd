extends Projectile


func initialize(master_id: int, spawn_time: int, player_owned: bool):
    set_network_master(master_id)
    set_name("B_%d_%d" % [master_id, spawn_time])
    player_shot = player_owned
    p_origin = global_transform.origin
    p_basis = global_transform.basis
    velocity = -transform.basis.z * move_speed
    velocity.y = 0
    p_velocity = velocity
    $Particles.emitting = true
    if player_owned and is_network_master():
        GameState.add_player_shot(master_id)
