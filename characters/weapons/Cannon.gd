extends AbstractWeapon


func _ready():
	._ready()
	is_primary = true


func _fire():
	if can_fire():
		var shot = ordnance.instance()
		shot.global_transform = fire_point.global_transform
		var scene_root = get_tree().get_root().get_children()[0]
		shot.initialize()
		scene_root.add_child(shot)
		live_rounds += 1
		start_cooldown()
