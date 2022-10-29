extends EnemyState

var refresh_timer: SceneTreeTimer


func enter(_msg: Dictionary = {}) -> void:
    if is_network_master():
        _on_refresh_timeout()


func exit() -> void:
    refresh_timer.disconnect("timeout", self, "_on_refresh_timeout")


func update(_delta: float) -> void:
    if paused:
        return

    if not enemy.ai_shots_to_block.empty():
        enemy.get_shot_block_aim_location()
        if is_instance_valid(enemy.ai_shot_block_target):
            enemy.turret_root.rpc_unreliable("set_look_location", enemy.aim_location)
            if enemy.can_block_shot():
                enemy.get_node("WeaponController").rpc("fire_primary", OS.get_system_time_msecs())
        return

    enemy.ai_target = enemy.find_target_player()
    if is_instance_valid(enemy.ai_target):
        machine.transition_to("Engaging")


func _on_refresh_timeout() -> void:
    if machine.state != self:
        return

    if is_inside_tree():
        refresh_timer = get_tree().create_timer(enemy.ai_search_time)
        refresh_timer.connect("timeout", self, "_on_refresh_timeout")

    if paused:
        return

    if enemy.ai_shots_to_block.empty():
        enemy.get_random_aim_location()
    enemy.navigator.set_random_world_destination()
    enemy.navigator.start_move()
