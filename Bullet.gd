extends KinematicBody

export var move_speed := 5
var velocity := Vector3.ZERO

func initialize(start_position, start_direction):
	look_at_from_position(start_position, start_direction, Vector3.UP)
	velocity = Vector3.FORWARD * move_speed
	velocity = velocity.rotated(Vector3.UP, rotation.y)


func _physics_process(delta):
	velocity = -transform.basis.z * move_speed
	move_and_slide(velocity, Vector3.UP)
