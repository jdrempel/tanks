extends Node

class_name State

var machine = null

var paused = false


func enter(_msg: Dictionary = {}) -> void:
    pass


func exit() -> void:
    pass


func set_paused(val: bool) -> void:
    paused = val


func handle_input(_event: InputEvent) -> void:
    pass


func update(_delta: float) -> void:
    pass


func physics_update(_delta: float) -> void:
    pass
