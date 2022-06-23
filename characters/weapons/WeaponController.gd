extends Node

export(Array, PackedScene) var weapons: Array = []

var _weapons: Array

export var player_controlled = false

var active_primary = null
var active_secondary = null


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


func _ready():
	for weapon in weapons:
		var instance = weapon.instance()
		add_child(instance)
	
	for weapon in get_children():
		if weapon.is_primary:
			weapon.is_active = true
			active_primary = weapon
			break
	
	for weapon in get_children():
		if weapon.is_secondary:
			weapon.is_active = true
			active_secondary = weapon
			break


func _process(delta):
	if player_controlled:
		if Input.is_action_just_pressed("fire_primary"):
			if active_primary != null:
				active_primary._fire()
		
		if Input.is_action_just_pressed("fire_secondary"):
			if active_secondary != null:
				active_secondary._fire()
