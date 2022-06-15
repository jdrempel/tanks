extends Spatial

export(PackedScene) var ordnance

onready var drop_plane = Plane(Vector3.UP, global_transform.origin.y)
onready var camera = get_viewport().get_camera()

func _process(delta):
	var mouse_position = get_viewport().get_mouse_position()
	var mouse_pos_3d = drop_plane.intersects_ray(
		camera.project_ray_origin(mouse_position),
		camera.project_ray_normal(mouse_position)
	)
	look_at(mouse_pos_3d, Vector3.UP)
	
	if Input.is_action_just_pressed("fire_primary"):
		var shot = ordnance.instance()
		shot.global_transform = $FirePoint.global_transform
		var scene_root = get_tree().get_root().get_children()[0]
		shot.initialize()
		scene_root.add_child(shot)
