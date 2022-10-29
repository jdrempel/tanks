extends EnemyState

var refresh_timer: SceneTreeTimer


func enter(_msg: Dictionary = {}) -> void:
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
            elif enemy.ai_dodge_skill >= enemy.ai_shots_to_block.size():
                # TODO no they should dodge not flee
                machine.transition_to("Fleeing")
            else:
                machine.transition_to("Fleeing")
        return

    enemy.get_target_aim_location()
    if not enemy.keep_target_player():
        machine.transition_to("Searching")
    else:
        enemy.turret_root.rpc_unreliable("set_look_location", enemy.aim_location)
        if is_instance_valid(enemy.ai_target):
            if enemy.is_target_in_sight():
                if enemy.is_target_acquired():
                    enemy.get_node("WeaponController").rpc("fire_primary", OS.get_system_time_msecs())


func _on_refresh_timeout() -> void:
    if machine.state != self:
        return

    if is_inside_tree():
        refresh_timer = get_tree().create_timer(enemy.ai_engage_time)
        refresh_timer.connect("timeout", self, "_on_refresh_timeout")

    if paused:
        return

    enemy.add_aim_jitter()

    if is_instance_valid(enemy.ai_target):
        enemy.navigator.set_destination(enemy.ai_target.global_transform.origin)
        enemy.navigator.start_move()
