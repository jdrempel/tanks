extends ColorRect


func _on_Resume_pressed() -> void:
    GameState.resume_level()


func _on_Leave_pressed() -> void:
    # Multiplayer.disconnect_from_game()
    GameState.reset(true)
