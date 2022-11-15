class_name CorkBlock extends StaticBody


func _ready() -> void:
    connect("tree_exited", GameState.current_level, "queue_rebake_navigation")


func destroy() -> void:
    queue_free()
