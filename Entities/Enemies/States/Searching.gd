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

    if enemy.navigator.is_dodging() and enemy.navigator.is_at_path_node():
        enemy.navigator.end_dodge()

    if not enemy.targeting.shots_to_block.empty():
        enemy.targeting.get_shot_block_aim_location()
        if is_instance_valid(enemy.targeting.shot_block_target):
            enemy.turret_root.rpc_unreliable("set_look_location", enemy.targeting.aim_location)
            if enemy.can_block_shot():
                enemy.get_node("WeaponController").rpc("fire_primary", OS.get_system_time_msecs())
            elif enemy.ai_dodge_skill > 0:
                # Don't dodge or flee if it's an immobile unit (e.g. brown)
                if enemy.ai_dodge_skill >= enemy.targeting.shots_to_block.size():
                    enemy.navigator.start_dodge()
                    enemy.navigator.set_destination(enemy.targeting.get_safe_dodge_location())
                else:
                    enemy.navigator.end_dodge()
                    machine.transition_to("Fleeing")
        return

    enemy.targeting.player_target = enemy.targeting.find_target_player()
    if is_instance_valid(enemy.targeting.player_target):
        enemy.navigator.end_dodge()
        machine.transition_to("Engaging")


func _on_refresh_timeout() -> void:
    if machine.state != self:
        return

    if is_inside_tree():
        refresh_timer = get_tree().create_timer(enemy.ai_search_time)
        refresh_timer.connect("timeout", self, "_on_refresh_timeout")

    if paused:
        return

    if enemy.targeting.shots_to_block.empty():
        enemy.targeting.set_random_aim_location()
    enemy.navigator.set_random_world_destination()
    enemy.navigator.start_move()
