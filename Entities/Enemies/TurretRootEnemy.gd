extends Spatial

onready var drop_plane = Plane(Vector3.UP, global_transform.origin.y).normalized()
onready var drop_mesh = SphereMesh.new()
onready var drop_sphere = MeshInstance.new()

var look_location := Vector3.ZERO
var rotation_lerp

export var look_speed := 3.0  # rad/s


remotesync func set_look_location(raw_vector: Vector3):
    look_location = drop_plane.project(raw_vector)
    rotation_lerp = 0


func _ready():
    rpc_unreliable("set_look_location", Vector3.ZERO)
    if Globals.DEBUG:
        drop_mesh.radius = 0.1
        drop_mesh.height = 0.2
        drop_sphere.mesh = drop_mesh
        add_child(drop_sphere)


func get_angle_to_target() -> float:
    return (-global_transform.basis.z) \
        .signed_angle_to(look_location - global_transform.origin, Vector3.UP)


func look_at_target(delta: float) -> float:
    # Returns the signed angle between the normalized look vector and normalized
    # vector of origin-to-target.
    var angle_to_target = get_angle_to_target()
    var look_point = global_transform.origin + 2 * (-global_transform.basis.z) \
        .rotated(Vector3.UP, sign(angle_to_target) * sqrt(look_speed) * delta)
    look_at(look_point, Vector3.UP)
    if Globals.DEBUG:
        drop_sphere.global_transform.origin = look_point
    return angle_to_target


func _physics_process(delta):
    if get_parent().get_parent().paused:
        return

    var _x = look_at_target(delta)
