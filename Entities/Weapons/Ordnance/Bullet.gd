extends Projectile


func initialize(master_id: int, spawn_time: int):
    self.master_id = master_id
    set_network_master(MetaManager.player_manager.get_player_network_master(master_id))
    set_name("B_%d_%d" % [master_id, spawn_time])
    player_shot = master_id >= 0
    p_origin = global_transform.origin
    p_basis = global_transform.basis
    velocity = -transform.basis.z * move_speed
    velocity.y = 0
    p_velocity = velocity
    $Particles.emitting = true
    if player_shot and is_network_master():
        emit_signal("player_shot_fired", master_id)
