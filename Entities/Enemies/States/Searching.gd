extends EnemyState

var refresh_timer: SceneTreeTimer


func enter(_msg: Dictionary = {}) -> void:
    _on_refresh_timeout()


func exit() -> void:
    refresh_timer.disconnect("timeout", self, "_on_refresh_timeout")


func update(_delta: float) -> void:
    enemy.ai_target = enemy.find_target_player()
    if is_instance_valid(enemy.ai_target):
        machine.transition_to("Engaging")


func _on_refresh_timeout() -> void:
    if machine.state != self:
        return

    if is_inside_tree():
        refresh_timer = get_tree().create_timer(enemy.ai_search_time)
        refresh_timer.connect("timeout", self, "_on_refresh_timeout")
    enemy.get_random_aim_location()
    enemy.get_new_world_destination()
    enemy.start_move_to(enemy.ai_world_destination)
