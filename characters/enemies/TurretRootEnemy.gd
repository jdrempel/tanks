extends Spatial

onready var drop_plane = Plane(Vector3.UP, global_transform.origin.y)

var look_location := Vector3.ZERO

export var look_speed := 3.0  # rad/s


func set_look_location(raw_vector: Vector3):
	look_location = drop_plane.intersects_ray(
		raw_vector - Vector3.UP * 1000,
		raw_vector + Vector3.UP * 1000
	)


func _ready():
	set_look_location(Vector3.ZERO)


func _process(delta):
	look_at(look_location, Vector3.UP)
