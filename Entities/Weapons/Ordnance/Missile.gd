extends KinematicBody

export var move_speed := 11
var velocity := Vector3.ZERO

export var bounces_remaining := 2

func initialize(master_id: int, spawn_time: int):
    set_name("M_%d_%d" % [master_id, spawn_time])
    velocity = -transform.basis.z * move_speed
    velocity.y = 0


remotesync func destroy():
    AudioManager.play_sound($DestroySound)
    queue_free()


remotesync func impact(other):
    # play effects
    if not other.is_in_group("world"):
        other.rpc("destroy")
    rpc("destroy")


func _physics_process(delta):
    var collision = move_and_collide(velocity * delta)
    if collision:
        if collision.collider.is_in_group("world") and bounces_remaining > 0:
            velocity = velocity.bounce(collision.normal)
            look_at(transform.origin + velocity, Vector3.UP)
            move_and_collide(velocity * delta / 2)
            var bounce_pitch = 1 + 0.3 * bounces_remaining
            AudioManager.play_sound($BounceSound, bounce_pitch)
            bounces_remaining -= 1
        else:
            rpc("impact", collision.collider)


func _on_OrdnanceDetection_area_entered(area):
    var parent = area.get_parent()
    if parent.is_in_group("projectiles"):
        rpc("impact", parent)
