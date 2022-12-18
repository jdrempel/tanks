extends OptionButton


signal control_scheme_changed(player_id, scheme_id)


func _ready() -> void:
    add_item("Keyboard (WASD)")
    add_item("Keyboard (Arrows)")
    for id in Input.get_connected_joypads():
        add_item(Input.get_joy_name(id))
    # connect("control_scheme_changed", Cooperative, "_on_control_scheme_changed")


func _on_item_selected(index: int) -> void:
    var player_id = get_parent().get_index()
    emit_signal("control_scheme_changed", player_id, index)
