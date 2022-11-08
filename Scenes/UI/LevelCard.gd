extends Control


var disabled = false

signal pressed()


func _on_LevelCard_gui_input(event: InputEvent) -> void:
    if disabled:
        return
    if event is InputEventMouseButton and not event.is_pressed() and event.get_button_index() == BUTTON_LEFT:
        emit_signal("pressed", self)


func select() -> void:
    $Highlight.show()


func deselect() -> void:
    $Highlight.hide()


func disable() -> void:
    disabled = true
    modulate = Color(1, 1, 1, 0.5)


func enable() -> void:
    disabled = false
    modulate = Color(1, 1, 1, 1)
