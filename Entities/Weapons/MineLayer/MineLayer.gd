extends AbstractWeapon


func _fire(time: int, player: bool):
    if can_fire():
        var mine = ordnance.instance()
        var scene_root = GameState.current_level.get_node("Ordnance")
        scene_root.add_child(mine, true)
        mine.global_transform = fire_point.global_transform
        mine.initialize(get_network_master(), time, player)
        mine.connect("tree_exited", self, "subtract_live_round")
        live_rounds += 1
        start_cooldown()
        emit_signal("fired")
