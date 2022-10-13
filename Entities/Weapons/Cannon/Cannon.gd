extends AbstractWeapon


puppetsync func _fire():
    if can_fire():
        var shot = ordnance.instance()
        var scene_root = get_node("/root/Level")
        scene_root.add_child(shot)
        shot.global_transform = fire_point.global_transform
        shot.initialize(get_network_master())
        shot.connect("tree_exited", self, "subtract_live_round")
        live_rounds += 1
        start_cooldown()
        emit_signal("fired")
