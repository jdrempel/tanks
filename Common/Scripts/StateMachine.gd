extends Node

class_name StateMachine


export var initial_state := NodePath()
onready var state: State = get_node(initial_state)

signal transitioned(state_name)


func _ready() -> void:
    yield(owner, "ready")
    for child in get_children():
        child.machine = self
    if is_network_master():
        state.enter()


func _unhandled_input(event: InputEvent) -> void:
    if not is_network_master():
        return
    state.handle_input(event)


func _process(delta: float) -> void:
    if not is_network_master():
        return
    state.update(delta)


func _physics_process(delta: float) -> void:
    if not is_network_master():
        return
    state.physics_update(delta)


func transition_to(target_name: String, msg: Dictionary = {}):
    if not is_network_master():
        return

    if not has_node(target_name):
        return

    state.exit()
    state = get_node(target_name)
    print("Entered %s" % target_name)
    state.enter(msg)
