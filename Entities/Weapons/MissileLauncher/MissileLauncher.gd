extends AbstractWeapon


func _ready():
    ._ready()
    is_primary = true
    var fire_point_name = "FirePointCannon"
    set_fire_point(fire_point_name)


func _fire():
    if can_fire():
        var shot = ordnance.instance()
        shot.global_transform = fire_point.global_transform
        var scene_root = get_tree().get_root().get_children()[0]
        shot.initialize()
        scene_root.add_child(shot)
        shot.connect("tree_exited", self, "subtract_live_round")
        live_rounds += 1
        start_cooldown()
