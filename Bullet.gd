extends KinematicBody

export var move_speed := 5
var velocity := Vector3.ZERO

func initialize():
	velocity = -transform.basis.z * move_speed


func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.normal)
		move_and_collide(velocity * delta)
