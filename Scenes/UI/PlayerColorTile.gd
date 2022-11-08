extends Control


const LOCAL_BORDER_COLOR = Color(1, 1, 1)
const REMOTE_BORDER_COLOR = Color(0.6, 0.6, 0.6)

var disabled = false

signal pressed(who_am_i)


func initialize(color_name: String) -> void:
    $Background.color = Color(Data.player_colors[color_name])
    hint_tooltip = color_name
    size_flags_horizontal = SIZE_EXPAND_FILL
    size_flags_vertical = SIZE_EXPAND_FILL
    set_name(color_name)


func select(remote_player: bool) -> void:
    if remote_player:
        $Outline.border_color = REMOTE_BORDER_COLOR
    else:
        $Outline.border_color = LOCAL_BORDER_COLOR
    $Outline.show()


func deselect() -> void:
    $Outline.hide()


func disable() -> void:
    disabled = true


func enable() -> void:
    disabled = false


func _on_Background_gui_input(event: InputEvent) -> void:
    if disabled:
        return
    if event is InputEventMouseButton and not event.is_pressed() and event.get_button_index() == BUTTON_LEFT:
        emit_signal("pressed", self)
