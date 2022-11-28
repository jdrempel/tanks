class_name ProjectileShooter extends AbstractWeapon


func _fire(time: int, player: bool):
    if can_fire():
        var shot = ordnance.instance()
        var scene_root = GameState.current_level.ordnance_root
        scene_root.add_child(shot, true)
        shot.global_transform = fire_point.global_transform
        shot.initialize(get_network_master(), time, player)
        shot.connect("tree_exited", self, "subtract_live_round")
        add_live_round()
        start_cooldown()
        emit_signal("fired")
