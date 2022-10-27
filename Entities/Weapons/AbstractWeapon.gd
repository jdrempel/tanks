class_name AbstractWeapon extends Node

export(PackedScene) var ordnance

export var cooldown_time: float = 0.0

export var max_ammo: int = -1
export var max_live_rounds: int = 5

export(Globals.WeaponType) var category: int

var is_active: bool
var controller: Node = null

var off_cooldown: bool = false
var ammo: int = -1
var live_rounds: int = 0
export var fire_point_path := NodePath()
var fire_point: Spatial

signal fired()


func _ready():
    yield(get_parent(), "ready")

    assert(controller != null)
    if category == Globals.WeaponType.Primary:
        connect("fired", controller, "_on_primary_fired")
    else:
        connect("fired", controller, "_on_secondary_fired")

    fire_point = get_node(fire_point_path)
    assert(fire_point != null)

    ammo = max_ammo
    off_cooldown = true
    if cooldown_time > 0:
        var timer = Timer.new()
        timer.name = "CooldownTimer"
        timer.one_shot = true
        add_child(timer)
        timer.connect("timeout", self, "_on_finish_cooldown")


func _fire(time: int):
    pass


func can_fire() -> bool:
    return is_active and off_cooldown and ammo != 0 and live_rounds < max_live_rounds


func start_cooldown():
    $CooldownTimer.start(cooldown_time)
    off_cooldown = false


func _on_finish_cooldown():
    off_cooldown = true


func subtract_live_round():
    live_rounds -= 1
