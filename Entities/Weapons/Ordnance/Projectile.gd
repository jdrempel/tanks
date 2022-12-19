class_name Projectile
extends KinematicBody


var paused := false
export var move_speed := 3.0
var velocity := Vector3.ZERO

# Network stuff
puppet var p_origin := Vector3.ZERO
puppet var p_basis := Basis.IDENTITY
puppet var p_velocity := Vector3.ZERO

var master_id := -1
var player_shot = false
var is_dying = false

export var bounces_remaining := 1
export(PackedScene) var death_explosion: PackedScene

var enemy_type_regex = RegEx.new()
var player_regex = RegEx.new()

signal player_shot_fired(player)
signal player_shot_destroyed(player)
signal killed_enemy(player, enemy_type)


func _init() -> void:
    enemy_type_regex.compile("^Enemy(?<type>[A-Za-z]+)\\d*$")
    player_regex.compile("^\\d+$")


func _ready() -> void:
    connect("player_shot_fired", MetaManager.stats_manager, "add_player_shot")
    connect("killed_enemy", MetaManager.stats_manager, "add_player_kill")


func initialize(master_id: int, spawn_time: int):
    pass


remotesync func destroy():
    AudioManager.play_sound($DestroySound)
    GameState.current_level.remove_blockable_shot(self)
    emit_signal("player_shot_destroyed", master_id)
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
    if is_network_master() and is_instance_valid(other) and other.has_method("destroy"):
        other.rpc("destroy")
        if player_shot:
            var result = enemy_type_regex.search(other.get_name())
            if result != null:
                emit_signal("killed_enemy", master_id, result.get_string("type"))
                AudioManager.play_sound(GameState.current_level.get_node(
                    "Players/%d/HooraySound" % master_id
                ), 1.33)
            result = player_regex.search(other.get_name())
            if result != null and other is Player and master_id != other.get_name().to_int():
                MetaManager.stats_manager.add_team_kill(master_id)
                AudioManager.play_sound(GameState.current_level.get_node(
                    "Players/%d/OhNoSound" % master_id
                ), 1.0)
    destroy()


remote func update_pvr(pos, vel, rot):
    p_origin = pos
    p_basis = rot
    p_velocity = vel


func set_paused(val: bool) -> void:
    paused = val


remotesync func bounce(pre_velocity: Vector3, normal: Vector3) -> void:
    velocity = pre_velocity.bounce(normal)
    look_at(transform.origin + velocity, Vector3.UP)
    bounces_remaining -= 1
    AudioManager.play_sound($BounceSound)


func update_parameters() -> void:
    global_transform.origin = p_origin
    global_transform.basis = p_basis
    velocity = p_velocity


func _physics_process(delta):
    if paused:
        return

    if not is_network_master():
        update_parameters()
        return

    if not is_dying:
        var pre_collision_velocity = velocity
        velocity = move_and_slide(velocity)
        if get_slide_count() > 0:
            var collision = get_slide_collision(0)
            if collision:
                if bounces_remaining > 0 and \
                        (not collision.collider.has_method("destroy") or collision.collider is CorkBlock):
                    rpc("bounce", pre_collision_velocity, collision.normal)
                else:
                    var other_path = collision.collider.get_path()
                    rpc("impact", other_path)
                    is_dying = true
        if not is_dying:
            rpc("update_pvr", global_transform.origin, velocity, global_transform.basis)


func _on_OrdnanceDetection_area_entered(area):
    var parent = area.get_parent()
    if parent.is_in_group("projectiles"):
        impact(parent.get_path())
