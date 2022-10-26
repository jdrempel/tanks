extends AbstractWeapon


func _fire(time: int):
    if can_fire():
        var shot = ordnance.instance()
        shot.global_transform = fire_point.global_transform
        var scene_root = get_tree().get_root().get_children()[0]
        shot.initialize(get_network_master(), time)
        scene_root.add_child(shot, true)
        shot.connect("tree_exited", self, "subtract_live_round")
        live_rounds += 1
        start_cooldown()
