extends Spatial

onready var drop_plane = Plane(Vector3.UP, global_transform.origin.y).normalized()
onready var drop_mesh = SphereMesh.new()
onready var drop_sphere = MeshInstance.new()

var look_location := Vector3.ZERO
var rotation_lerp

export var look_speed := 3.0  # rad/s


func set_look_location(raw_vector: Vector3):
	look_location = drop_plane.project(raw_vector)
	rotation_lerp = 0


func _ready():
	set_look_location(Vector3.ZERO)


func _process(delta):
	var target_rotation = global_transform.looking_at(look_location, Vector3.UP).basis
	if rotation_lerp < 1:
		rotation_lerp += delta * look_speed
	elif rotation_lerp > 1:
		rotation_lerp = 1
	global_transform.basis = global_transform.basis.slerp(target_rotation, rotation_lerp).orthonormalized()
