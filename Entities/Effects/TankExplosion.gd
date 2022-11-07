extends Spatial


func _ready() -> void:
    var tween = get_tree().create_tween()
    tween.tween_property($OmniLight, "light_energy", 0.0, 0.7) \
        .set_ease(Tween.EASE_OUT) \
        .set_trans(Tween.TRANS_QUAD)
    tween.tween_callback($OmniLight, "queue_free")
