extends AbstractWeapon


func _fire():
    if can_fire():
        var shot = ordnance.instance()
        shot.global_transform = fire_point.global_transform
        var scene_root = get_node("/root/Level")
        shot.initialize()
        scene_root.add_child(shot)
        shot.connect("tree_exited", self, "subtract_live_round")
        live_rounds += 1
        start_cooldown()
