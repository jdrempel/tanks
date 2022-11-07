extends Node


func play_sound(sound: AudioStreamPlayer3D, pitch: float = 1.0):
    if not is_instance_valid(sound):
        return
    var new_sound: AudioStreamPlayer3D = sound.duplicate()
    new_sound.connect("finished", self, "_on_sound_finished", [new_sound])
    add_child(new_sound)
    new_sound.pitch_scale = pitch
    new_sound.play()


func _on_sound_finished(sound: AudioStreamPlayer3D):
    remove_child(sound)
