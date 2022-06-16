extends KinematicBody

export var move_speed := 3
var velocity := Vector3.ZERO

export var bounces_remaining := 1

func initialize():
	velocity = -transform.basis.z * move_speed
	velocity.y = 0


func destroy():
	queue_free()


func impact(other):
	# play effects
	if not other.is_in_group("world"):
		other.destroy()
	destroy()


func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)
	if collision:
		if collision.collider.is_in_group("world") and bounces_remaining > 0:
			velocity = velocity.bounce(collision.normal)
			look_at(transform.origin + velocity, Vector3.UP)
			move_and_collide(velocity * delta / 2)
			bounces_remaining -= 1
		else:
			impact(collision.collider)
