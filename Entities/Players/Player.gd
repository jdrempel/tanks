extends AbstractTank

class_name Player


func _ready():
    GameState.rpc("add_living_player")
    connect("destroyed", GameState, "_on_player_destroyed")

    if get_network_master() != 1:
        var material_p2 = load("res://Entities/Players/Resources/Materials/player2.tres") as Material
        $Body.material_override = material_p2
        $Body/TurretRoot/Turret.material_override = material_p2


remotesync func destroy():
    emit_signal("destroyed")
    queue_free()


func get_movement_vector():
    var target_direction: Vector3 = Vector3(
        Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
        0,
        Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
       )

    if target_direction.length():
        return target_direction.normalized()
    return target_direction


remote func update_pvr(pos, vel, rot):
    p_origin = pos
    p_basis = rot
    p_velocity = vel


func _physics_process(delta):
    if not is_network_master():
        # Player being controlled by remote source
        global_transform.origin = p_origin
        global_transform.basis = p_basis
        velocity = p_velocity
        return

    # Player being controlled by local client
    var target_direction = get_movement_vector()
    if target_direction != Vector3.ZERO:
        if target_direction != last_target_direction:
            set_target_location(target_direction)
        var vectors = rotate_body(delta, target_direction)
        var facing_vector = vectors[0]
        var opposing_vector = vectors[1]
        if facing_vector.dot(target_direction) > 0.999 or opposing_vector.dot(target_direction) > 0.999:
            velocity = move_and_slide(move_speed * target_direction, Vector3.UP)
    else:
        velocity = Vector3.ZERO

    last_target_direction = target_direction
    rpc_unreliable("update_pvr", global_transform.origin, velocity, global_transform.basis)
