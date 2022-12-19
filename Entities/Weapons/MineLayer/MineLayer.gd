extends AbstractWeapon


func _fire(time: int, master_id: int = -1):
    if can_fire():
        var mine = ordnance.instance()
        var scene_root = GameState.current_level.ordnance_root
        scene_root.add_child(mine, true)
        mine.global_transform = fire_point.global_transform
        mine.initialize(master_id, time)
        mine.connect("tree_exited", self, "subtract_live_round")
        live_rounds += 1
        start_cooldown()
        emit_signal("fired")
