extends Node

class_name AbstractWeapon

export(PackedScene) var ordnance

export var cooldown_time := 0.0

export var max_ammo := -1
export var max_live_rounds := 5

export var is_primary: bool
export var is_secondary: bool
export var is_active: bool

var off_cooldown := false
var ammo := -1
var live_rounds := 0
var fire_point: Spatial


func _ready():
	ammo = max_ammo
	off_cooldown = true
	if cooldown_time > 0:
		var timer = Timer.new()
		timer.name = "CooldownTimer"
		timer.owner = self
		timer.one_shot = true
		add_child(timer)
		timer.connect("timeout", self, "finish_cooldown")
	fire_point = get_parent().get_parent().find_node("FirePoint")


func _fire():
	pass


func can_fire() -> bool:
	return off_cooldown and ammo != 0 and live_rounds < max_live_rounds


func start_cooldown():
	$CooldownTimer.start(cooldown_time)
	off_cooldown = false


func finish_cooldown():
	off_cooldown = true


func subtract_live_round():
	live_rounds -= 1
