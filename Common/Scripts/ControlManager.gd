class_name ControlManager
extends Node


func get_movement_action_strength(player_id: int, dir: String) -> float:
    var player = MetaManager.player_manager.players.get(player_id)
    var action_string := "{scheme}_move_{dir}".format({
        scheme = Globals.SCHEME_TO_NAME_MAP[player.controls],
        dir = dir
       })
    return Input.get_action_strength(action_string)


func is_action_just_pressed(player_id: int, action: String) -> bool:
    var player = MetaManager.player_manager.players.get(player_id)
    var action_string := "{scheme}_{action}".format({
        scheme = Globals.SCHEME_TO_NAME_MAP[player.controls],
        action = action
       })
    return Input.is_action_just_pressed(action_string)


func get_aim_location(player_id: int, turret_plane: Plane,
                          player_node) -> Vector3:
    var player = MetaManager.player_manager.players.get(player_id)
    var far_vector = Vector3(10000, 0, 10000)
    match player.controls:
        Globals.ControlSchemes.KBM_ARROW, Globals.ControlSchemes.KBM_WASD:
            var mouse_position = player_node.get_viewport().get_mouse_position()
            return turret_plane.intersects_ray(
                Globals.camera.project_ray_origin(mouse_position),
                Globals.camera.project_ray_normal(mouse_position)
            )
        Globals.ControlSchemes.JOY_0, Globals.ControlSchemes.JOY_1:
            var action_string := "{scheme}_aim_%s".format({
                scheme = Globals.SCHEME_TO_NAME_MAP[player.controls]})
            return turret_plane.intersects_ray(
                player_node.global_transform.origin +
                    Vector3(
                        Input.get_action_strength(action_string % "right") -
                            Input.get_action_strength(action_string % "left"),
                        0,
                        Input.get_action_strength(action_string % "down") -
                            Input.get_action_strength(action_string % "up")
                    ),
                Vector3.UP
            )
    return far_vector
