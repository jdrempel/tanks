extends KinematicBody

export var move_speed := 3
var velocity := Vector3.ZERO

# Network stuff
puppet var p_origin := Vector3.ZERO
puppet var p_basis := Basis.IDENTITY
puppet var p_velocity := Vector3.ZERO

export var bounces_remaining := 1
export(PackedScene) var death_explosion: PackedScene

func initialize(master_id):
    # set_network_master()  # TODO try making the server actually spawn these
    velocity = -transform.basis.z * move_speed
    velocity.y = 0


remotesync func destroy():
    queue_free()


remotesync func impact(other_path: NodePath):
    # play effects
    var explosion: CPUParticles = death_explosion.instance()
    get_parent().add_child(explosion)
    explosion.global_transform = self.global_transform
    explosion.global_transform.origin += velocity.normalized() * 0.05
    var explosion_self_destruct = get_tree().create_timer(1.0)
    explosion_self_destruct.connect("timeout", explosion, "queue_free")
    explosion.emitting = true

    var other = get_node(other_path)
    if other.has_method("destroy"):
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
                var other_path = collision.collider.get_path()
                rpc("impact", other_path)
    rpc_unreliable("update_pvr", global_transform.origin, velocity, global_transform.basis)


func _on_OrdnanceDetection_area_entered(area):
    var parent = area.get_parent()
    if parent.is_in_group("projectiles"):
        impact(parent.get_path())
