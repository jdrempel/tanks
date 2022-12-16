class_name Player
extends AbstractTank

export(PackedScene) var death_explosion

var server: Node
var input_queue = []
var state_queue = []


func _ready():
    assert(is_instance_valid(GameState.current_level))
    connect("tree_exited", GameState.current_level, "_on_player_destroyed")

    server = $Server
    server.initialize(self)

    turret_root = $Body/TurretRoot


func setup_tank_color(master_id: int) -> void:
    var player_color_name = Multiplayer.players[master_id].color
    var texture = load("res://Entities/Players/Resources/Materials/tank_player_%s.png" % \
        player_color_name.to_lower())
    $Body.get("material/0").albedo_texture = texture
    $Body/TreadLeft.get("material/0").albedo_texture = texture
    $Body/TreadRight.get("material/0").albedo_texture = texture
    $Body/TurretRoot/Turret.get("material/0").albedo_texture = texture
    $Body/TurretRoot/Barrel.get("material/0").albedo_texture = texture


remotesync func destroy():
    if is_network_master() or get_tree().get_network_unique_id() == 0 or Multiplayer.players.size() == 1:
        emit_signal("destroyed", get_name().to_int())
    var explosion = death_explosion.instance()
    get_parent().get_parent().add_child(explosion)
    explosion.global_transform.origin = self.global_transform.origin
    var player_color_name = Multiplayer.players[get_network_master()].color
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


func get_player_input() -> Dictionary:
    var input_direction = Vector3(
        Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
        0,
        Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
       )

    var player_input = {
        time = OS.get_system_time_msecs(),
        movement = input_direction,
        look_location = turret_root.get_look_location(),
    }

    return player_input


func get_player_state() -> Dictionary:
    return {
        time = OS.get_system_time_msecs(),
        position = global_transform.origin,
        basis = global_transform.basis,
        velocity = velocity,
        look_location = turret_root.get_look_location()
       }


func receive_player_state(player_state: Dictionary) -> void:
    state_queue.push_back(player_state)


func get_movement_vector():
    var target_direction: Vector3
    if input_queue.empty():
        return Vector3.ZERO
    var earliest_input = input_queue.front()
    while earliest_input.time <= OS.get_system_time_msecs() - Globals.input_delay_ms:
        input_queue.pop_front()
        target_direction = earliest_input.movement
        if input_queue.empty():
            break
        earliest_input = input_queue.front()
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
        if state_queue.empty():
            return
        var next_state = state_queue.front()
        while next_state.time <= OS.get_system_time_msecs():
            global_transform.origin = next_state.position
            global_transform.basis = next_state.basis
            velocity = next_state.velocity
            turret_root.set_look_location(next_state.look_location)
            state_queue.pop_front()
            if state_queue.empty():
                break
            next_state = state_queue.front()
        make_tracks(velocity)
        return

    # Player being controlled by local client
    input_queue.push_back(get_player_input())
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

    make_tracks(velocity)

    last_target_direction = target_direction
    rpc_unreliable("update_pvr", global_transform.origin, velocity, global_transform.basis)
