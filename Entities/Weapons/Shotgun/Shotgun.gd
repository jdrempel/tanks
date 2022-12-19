extends AbstractWeapon


export var rounds_per_shot := 3

export(Array, NodePath) var shotgun_fire_point_paths = []
var shotgun_fire_points = []


func _ready() -> void:
    ._ready()
    for path in shotgun_fire_point_paths:
        shotgun_fire_points.append(get_node(path))
    max_live_rounds = 2 * rounds_per_shot


func can_fire() -> bool:
    return is_active and off_cooldown and ammo != 0 and (live_rounds + 2) < max_live_rounds


func _fire(time: int, master_id: int = -1):
    if can_fire():
        for round_id in rounds_per_shot:
            var shot = ordnance.instance()
            var scene_root = GameState.current_level.ordnance_root
            scene_root.add_child(shot, true)
            shot.global_transform = shotgun_fire_points[round_id % shotgun_fire_points.size()]\
                .global_transform
            shot.initialize(master_id, time)
            shot.connect("tree_exited", self, "subtract_live_round")
            add_live_round()
        start_cooldown()
        emit_signal("fired")

