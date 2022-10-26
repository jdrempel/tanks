class_name ProjectileShooter extends AbstractWeapon


func _fire(time: int):
    if can_fire():
        var shot = ordnance.instance()
        var scene_root = GameState.current_level.get_node("Ordnance")
        scene_root.add_child(shot, true)
        shot.global_transform = fire_point.global_transform
        shot.initialize(get_network_master(), time)
        shot.connect("tree_exited", self, "subtract_live_round")
        live_rounds += 1
        start_cooldown()
        emit_signal("fired")
