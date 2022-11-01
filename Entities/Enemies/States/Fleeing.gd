extends EnemyState

var refresh_timer: SceneTreeTimer


func enter(_msg: Dictionary = {}) -> void:
    if is_network_master():
        if is_inside_tree():
            refresh_timer = get_tree().create_timer(enemy.ai_flee_time)
            refresh_timer.connect("timeout", self, "_on_refresh_timeout")
        enemy.navigator.set_flee_destination()


func exit() -> void:
    refresh_timer.disconnect("timeout", self, "_on_refresh_timeout")


func update(_delta: float) -> void:
    if paused:
        return

    if not enemy.targeting.shots_to_block.empty():
        enemy.targeting.get_shot_block_aim_location()
        if is_instance_valid(enemy.targeting.shot_block_target):
            enemy.turret_root.rpc_unreliable("set_look_location", enemy.targeting.aim_location)
            if enemy.can_block_shot():
                enemy.get_node("WeaponController").rpc("fire_primary", OS.get_system_time_msecs())
        return


func _on_refresh_timeout() -> void:
    if machine.state != self:
        return

    if is_inside_tree():
        refresh_timer = get_tree().create_timer(enemy.ai_flee_time)
        refresh_timer.connect("timeout", self, "_on_refresh_timeout")

    if paused:
        return

    machine.transition_to("Searching")


