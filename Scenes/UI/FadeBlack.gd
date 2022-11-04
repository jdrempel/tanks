extends Control


const COLOR_OFF = Color(1, 1, 1, 0)
const COLOR_ON = Color(1, 1, 1, 1)

signal faded()


func fade_to_black() -> void:
    $FadeTween.interpolate_property(
        $ColorRect, "modulate", COLOR_OFF, COLOR_ON, Globals.FADE_TIME, Tween.TRANS_CIRC,
        Tween.EASE_OUT)
    $FadeTween.start()
    yield($FadeTween, "tween_completed")
    emit_signal("faded")


func fade_from_black() -> void:
    $FadeTween.interpolate_property(
        $ColorRect, "modulate", COLOR_ON, COLOR_OFF, Globals.FADE_TIME, Tween.TRANS_CIRC,
        Tween.EASE_OUT)
    $FadeTween.start()
    yield($FadeTween, "tween_completed")
    queue_free()
