extends HBoxContainer


var tile_scene = preload("res://Scenes/UI/PlayerColorTile.tscn")

var local_selection = null
var remote_selection = null

signal selection_changed(to)


func _ready() -> void:
    # Multiplayer.connect("remote_player_color_changed", self, "remote_select_color")
    for color_name in Data.player_colors:
        var new_tile = tile_scene.instance()
        new_tile.initialize(color_name)
        add_child(new_tile)
        new_tile.connect("pressed", self, "_on_child_selected")


func _on_child_selected(child: Control) -> void:
    if is_instance_valid(local_selection):
        local_selection.deselect()
    child.select(false)
    local_selection = child
    emit_signal("selection_changed", local_selection.get_name())


func remote_select_color(color_name: String) -> void:
    if is_instance_valid(remote_selection):
        remote_selection.deselect()
    var new_selection = get_node(color_name)
    new_selection.select(true)
    remote_selection = new_selection
    # Don't emit the signal (RIP stack)
