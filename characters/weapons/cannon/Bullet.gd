extends KinematicBody

export var move_speed := 3
var velocity := Vector3.ZERO

# Network stuff
puppet var p_origin := Vector3.ZERO
puppet var p_basis := Basis.IDENTITY
puppet var p_velocity := Vector3.ZERO

export var bounces_remaining := 1

func initialize(master_id):
    # set_network_master()  # TODO try making the server actually spawn these
    velocity = -transform.basis.z * move_speed
    velocity.y = 0


remotesync func destroy():
    queue_free()


remotesync func impact(other):
    # play effects
    if not other.has_method("is_in_group"):
        other = instance_from_id(other.object_id)
        print_debug(other)
    if not other.is_in_group("world"):
        other.destroy()
        other.rpc("destroy")
    rpc("destroy")


remote func update_pvr(pos, vel, rot):
    p_origin = pos
    p_basis = rot
    p_velocity = vel


func _physics_process(delta):
    if not is_network_master():
        global_transform.origin = p_origin
        global_transform.basis = p_basis
        velocity = p_velocity

    var pre_collision_velocity = velocity
    velocity = move_and_slide(velocity)
    if get_slide_count() > 0:
        var collision = get_slide_collision(0)
        if collision:
            if collision.collider.is_in_group("world") and bounces_remaining > 0:
                velocity = pre_collision_velocity.bounce(collision.normal)
                look_at(transform.origin + velocity, Vector3.UP)
                bounces_remaining -= 1
            else:
                rpc("impact", collision.collider)
    rpc_unreliable("update_pvr", global_transform.origin, velocity, global_transform.basis)


func _on_OrdnanceDetection_area_entered(area):
    var parent = area.get_parent()
    if parent.is_in_group("projectiles"):
        impact(parent)
