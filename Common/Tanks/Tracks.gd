extends Spatial


var lifetime := 30.0


func _ready() -> void:
    var tween = get_tree().create_tween()
    tween.tween_property(
        $Left.get("material/0"), "shader_param/a", Color(0.145, 0.145, 0.145, 0.0),
        lifetime)
    tween.tween_callback(self, "queue_free")
