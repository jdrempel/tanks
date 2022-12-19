extends Projectile


func initialize(master_id: int, spawn_time: int):
    self.master_id = master_id
    set_network_master(MetaManager.player_manager.get_player_network_master(master_id))
    set_name("I_%d_%d" % [master_id, spawn_time])
    player_shot = master_id >= 0
    velocity = -transform.basis.z * move_speed
    velocity.y = 0
    $Particles.emitting = true
    if player_shot and is_network_master():
        emit_signal("player_shot_fired", master_id)


remotesync func impact(other_path: NodePath):
    var other = get_node(other_path)
    if other == self:
        return
    if is_network_master() and is_instance_valid(other) and other.has_method("destroy"):
        other.rpc("destroy")
    destroy()


remotesync func destroy():
    if is_dying:
        return
    is_dying = true
    var bodies_inside = $ExplosionArea.get_overlapping_bodies()
    for body in bodies_inside:
        print(body.get_name())
        if (not body.is_in_group("static")) and body != self and body.has_method("destroy"):
            body.destroy()
        elif body.owner is CorkBlock:
            body.owner.destroy()
    var explosion = death_explosion.instance()
    get_parent().add_child(explosion)
    explosion.global_transform.origin = self.global_transform.origin
    for child in explosion.get_children():
        if not (child is CPUParticles):
            continue
        child.emitting = true
    Globals.camera.add_trauma(40.0)
    AudioManager.play_sound($DestroySound)
    queue_free()
