extends Node


var tank: AbstractTank


func _ready() -> void:
    yield(get_parent(), "ready")
    tank = get_parent()
    assert(is_instance_valid(tank))


func engage() -> void:
    tank.set_invisible(true)


func disengage() -> void:
    tank.set_invsisible(false)
