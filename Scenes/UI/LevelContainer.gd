extends HBoxContainer


var card_scene = preload("res://Scenes/UI/LevelCard.tscn")

var selection: Control = null
var disabled = false

signal selection_changed(new_selection)


func _ready() -> void:
    var all_levels = Data.level_data.get_all()
    for level_id in all_levels:
        var new_card = card_scene.instance()
        new_card.get_node("Label").text = all_levels[level_id].name
        new_card.get_node("Thumb").texture = load("res://Scenes/UI/%s" % all_levels["Level1"].thumb)
        new_card.name = level_id
        add_child(new_card, true)
        new_card.connect("pressed", self, "_on_child_selected")


func set_selection(level_id: String) -> void:
    if selection != null:
        selection.deselect()
    var child = get_node(level_id)
    child.select()
    selection = child
    # Don't emit the signal though (RIP stack)


func _on_child_selected(child: Control) -> void:
    if disabled:
        return
    if selection != null:
        selection.deselect()
    child.select()
    selection = child
    emit_signal("selection_changed", selection.get_name())


func disable() -> void:
    disabled = true
    modulate = Color(1, 1, 1, 0.5)


func enable() -> void:
    disabled = false
    modulate = Color(1, 1, 1, 1)
