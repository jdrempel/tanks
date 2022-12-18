extends AbstractTank

class_name Player

export(Material) var material_p1
export(Material) var material_p2
export(PackedScene) var death_explosion


func _ready():
    assert(is_instance_valid(GameState.current_level))
    connect("tree_exited", GameState.current_level, "_on_player_destroyed")


func setup_tank_color(master_id: int) -> void:
    var player_color_name = MetaManager.player_manager.players[master_id].get_color_name()
    var texture = load("res://Entities/Players/Resources/Materials/tank_player_%s.png" % \
        player_color_name.to_lower())
    $Body.get("material/0").albedo_texture = texture
    $Body/TreadLeft.get("material/0").albedo_texture = texture
    $Body/TreadRight.get("material/0").albedo_texture = texture
    $Body/TurretRoot/Turret.get("material/0").albedo_texture = texture
    $Body/TurretRoot/Barrel.get("material/0").albedo_texture = texture


remotesync func destroy():
    if is_network_master() or get_tree().get_network_unique_id() == 0 or MetaManager.player_manager.players.size() == 1:
        emit_signal("destroyed", get_name().to_int())
    var explosion = death_explosion.instance()
    get_parent().get_parent().add_child(explosion)
    explosion.global_transform.origin = self.global_transform.origin
    var player_color_name = MetaManager.player_manager.players[get_name().to_int()].get_color_name()
    var player_color = Color(Data.player_colors[player_color_name])
    for child in explosion.get_children():
        if child is MeshInstance:
            child.get("material/0").albedo_color = player_color
            continue
        if child is CPUParticles:
            child.emitting = true
    Globals.camera.add_trauma(60)
    AudioManager.play_sound($DestroySound)
    queue_free()


func get_movement_action_strength(dir: String) -> float:
    return MetaManager.control_manager.get_movement_action_strength(get_name().to_int(), dir)


func get_movement_vector():
    if paused:
        $MovementSound.stop()
        return Vector3.ZERO

    var target_direction: Vector3 = Vector3(
        get_movement_action_strength("right") - get_movement_action_strength("left"),
        0,
        get_movement_action_strength("down") - get_movement_action_strength("up")
       )

    if target_direction.length():
        if not $MovementSound.playing:
            $MovementSound.play()
        return target_direction.normalized()
    else:
        if $MovementSound.playing:
            $MovementSound.stop()
    return target_direction


func _physics_process(delta):

    if not is_network_master():
        # Player being controlled by remote source
        global_transform.origin = p_origin
        global_transform.basis = p_basis
        velocity = p_velocity
        make_tracks(velocity)
        return

    # Player being controlled by local client
    var target_direction = get_movement_vector()
    if target_direction != Vector3.ZERO:
        if target_direction != last_target_direction:
            set_target_location(target_direction)
        var vectors = rotate_body(delta, target_direction)
        var facing_vector = vectors[0]
        var opposing_vector = vectors[1]
        if facing_vector.dot(target_direction) > 0.95 or opposing_vector.dot(target_direction) > 0.95:
            velocity = move_and_slide(move_speed * target_direction, Vector3.UP)
    else:
        velocity = Vector3.ZERO

    make_tracks(velocity)

    last_target_direction = target_direction
    rpc_unreliable("update_pvr", global_transform.origin, velocity, global_transform.basis)
