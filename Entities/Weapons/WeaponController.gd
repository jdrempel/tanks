extends Node

export var player_controlled = false

export var initial_primary_path := NodePath()
export var initial_secondary_path := NodePath()

var active_primary = null
var active_secondary = null

var primary_ord_speed: float
var primary_num_bounces: int

export var primary_effect_path := NodePath()
var primary_fire_effect: CPUParticles
export var secondary_effect_path := NodePath()
var secondary_fire_effect: CPUParticles


func _ready():
    connect("ready", get_parent(), "_post_init")

    if not primary_effect_path.is_empty():
        primary_fire_effect = get_node(primary_effect_path)
    if not secondary_effect_path.is_empty():
        secondary_fire_effect = get_node(secondary_effect_path)

    if not initial_primary_path.is_empty():
        active_primary = get_node(initial_primary_path)
        active_primary.is_active = true
        var test_ordnance = active_primary.ordnance.instance()
        primary_ord_speed = test_ordnance.move_speed
        primary_num_bounces = test_ordnance.bounces_remaining

    if not initial_secondary_path.is_empty():
        active_secondary = get_node(initial_secondary_path)
        active_secondary.is_active = true

    for weapon in get_children():
        weapon.controller = self


func has_active_primary() -> bool:
    return active_primary != null


func has_active_secondary() -> bool:
    return active_secondary != null


func set_active_primary_cooldown(cooldown: float):
    if has_active_primary():
        active_primary.cooldown_time = cooldown


func set_active_secondary_cooldown(cooldown: float):
    if has_active_secondary():
        active_secondary.cooldown_time = cooldown


remotesync func fire_primary(time: int):
    if active_primary != null and not get_parent().paused:
        active_primary._fire(time, player_controlled)


remotesync func _on_primary_fired():
    if primary_fire_effect != null:
        primary_fire_effect.show()
        primary_fire_effect.emitting = true
        primary_fire_effect.restart()


remotesync func fire_secondary(time: int):
    if active_secondary != null and not get_parent().paused:
        active_secondary._fire(time, player_controlled)


remotesync func _on_secondary_fired():
    if secondary_fire_effect != null:
        secondary_fire_effect.show()
        secondary_fire_effect.emitting = true
        secondary_fire_effect.restart()


func _process(delta):
    if get_parent().paused:
        return

    if player_controlled and is_network_master():
        if GameState.player_manager.is_action_just_pressed(get_parent().name, "fire_primary"):
            rpc("fire_primary", OS.get_system_time_msecs())

        if GameState.player_manager.is_action_just_pressed(get_parent().name, "fire_secondary"):
            rpc("fire_secondary", OS.get_system_time_msecs())
