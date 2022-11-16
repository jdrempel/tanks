class_name CorkBlock extends StaticBody


func _ready() -> void:
    pass


func destroy() -> void:
    connect("tree_exited", GameState.current_level, "queue_rebake_navigation")
    queue_free()
