extends Spatial

export(PackedScene) var ordnance

onready var drop_plane = Plane(Vector3.UP, global_transform.origin.y)
onready var camera = get_viewport().get_camera()

var aim_pos_3d := Vector3.ZERO


func _ready():
    aim_pos_3d = drop_plane.intersects_ray(
        Vector3.ZERO,
        Vector3.UP
    )


remote func update_aim(pos):
    aim_pos_3d = pos


func get_look_location() -> Vector3:
    return aim_pos_3d


func set_look_location(location: Vector3) -> void:
    aim_pos_3d = location


func _physics_process(delta):
    if is_network_master():
        camera = Globals.camera
        var mouse_position = get_viewport().get_mouse_position()
        aim_pos_3d = drop_plane.intersects_ray(
            camera.project_ray_origin(mouse_position),
            camera.project_ray_normal(mouse_position)
        )
        rpc_unreliable("update_aim", aim_pos_3d)
    look_at(aim_pos_3d, Vector3.UP)
