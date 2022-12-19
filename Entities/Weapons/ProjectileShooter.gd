class_name ProjectileShooter extends AbstractWeapon


func _fire(time: int, master_id: int = -1):
    if can_fire():
        var shot = ordnance.instance()
        var scene_root = GameState.current_level.ordnance_root
        scene_root.add_child(shot, true)
        shot.global_transform = fire_point.global_transform
        shot.initialize(master_id, time)
        shot.connect("tree_exited", self, "subtract_live_round")
        add_live_round()
        start_cooldown()
        emit_signal("fired")
