extends Control


signal pressed()


func _on_LevelCard_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and not event.is_pressed() and event.get_button_index() == BUTTON_LEFT:
        emit_signal("pressed", self)


func select() -> void:
    $Highlight.show()


func deselect() -> void:
    $Highlight.hide()
