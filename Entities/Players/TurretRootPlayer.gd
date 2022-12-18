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


func _physics_process(delta):
    if is_network_master():
        aim_pos_3d = MetaManager.control_manager.get_aim_location(
            get_parent().get_parent().get_name().to_int(), drop_plane, get_parent().get_parent())
        rpc_unreliable("update_aim", aim_pos_3d)
    look_at(aim_pos_3d, Vector3.UP)
