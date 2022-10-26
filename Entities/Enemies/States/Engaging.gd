extends EnemyState

var refresh_timer: SceneTreeTimer


func enter(_msg: Dictionary = {}) -> void:
    _on_refresh_timeout()


func exit() -> void:
    refresh_timer.disconnect("timeout", self, "_on_refresh_timeout")


func update(_delta: float) -> void:
    enemy.get_target_aim_location()
    if not enemy.keep_target_player():
        machine.transition_to("Searching")
    else:
        enemy.turret_root.rpc_unreliable("set_look_location", enemy.aim_location)


func _on_refresh_timeout() -> void:
    if machine.state != self:
        return

    if is_inside_tree():
        refresh_timer = get_tree().create_timer(enemy.ai_engage_time)
        refresh_timer.connect("timeout", self, "_on_refresh_timeout")

    if is_instance_valid(enemy.ai_target):
        if enemy.is_target_in_sight():
            # TODO they shouldn't stop - instead enter a pattern in which they keep moving and only
            # change destinations when the player is suddenly no longer in sight lines
            enemy.start_move_to(enemy.global_transform.origin)
            enemy.add_aim_jitter()
            if enemy.is_target_acquired():
                enemy.get_node("WeaponController").rpc("fire_primary", OS.get_system_time_msecs())
        else:
            enemy.start_move_to(enemy.ai_target.global_transform.origin)
