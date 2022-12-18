class_name PlayerData
extends Resource


var uid: int
var name: String
var active: bool
var ready: bool
var color_str: String
var color: Color
var controls: int  # Globals.ControlScheme


func initialize(uid: int, name: String, active: bool, ready: bool,
                color_str: String, controls: int) -> PlayerData:
    self.uid = uid
    self.name = name
    self.active = active
    self.ready = ready
    self.controls = controls

    set_color(color_str)

    return self


func get_color_name() -> String:
    return color_str

func get_color() -> Color:
    return color

func set_color(new_color: String) -> void:
    color_str = new_color
    color = Color(Data.player_colors.get(new_color))

func set_ready(val: bool) -> void:
    ready = val

func toggle_ready() -> void:
    ready = not ready

func set_active(val: bool) -> void:
    active = val

func toggle_active() -> void:
    active = not active


