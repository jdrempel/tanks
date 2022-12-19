extends OptionButton


signal control_scheme_changed(player_id, scheme_id)


func _ready() -> void:
    MetaManager.connect("player_manager_changed", self, "_on_player_manager_changed")

    add_item("Keyboard (WASD)")
    add_item("Keyboard (Arrows)")
    for id in Input.get_connected_joypads():
        add_item(Input.get_joy_name(id))

    select(Globals.PLAYER_DEFAULT_SCHEME_MAP[get_parent().get_name()])


func _on_item_selected(index: int) -> void:
    var player_id = get_parent().get_index()
    emit_signal("control_scheme_changed", player_id, index)


func _on_player_manager_changed() -> void:
    connect("control_scheme_changed", MetaManager.player_manager, "_on_control_scheme_changed")
