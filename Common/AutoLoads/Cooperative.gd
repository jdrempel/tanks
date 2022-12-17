extends Node


enum Players { P1 = 0, P2, P3, P4 }
enum ControlSchemes { NONE = -1, KBM_WASD, KBM_ARROW, JOY_0, JOY_1 }

const RESET_PLAYERS := {
    Players.P1: { active = true, name = "Player 1", controls = ControlSchemes.NONE, color = "Blue" },
    Players.P2: { active = true, name = "Player 2", controls = ControlSchemes.NONE, color = "Red" },
    Players.P3: { active = false, name = "Player 3", controls = ControlSchemes.NONE, color = "Green" },
    Players.P4: { active = false, name = "Player 4", controls = ControlSchemes.NONE, color = "Yellow" },
}

var _peer
var players = RESET_PLAYERS


func host_game() -> void:
    _peer = NetworkedMultiplayerENet.new()
    _peer.create_server(Globals.DEFAULT_PORT, 1)
    get_tree().set_network_peer(_peer)


func _on_control_scheme_changed(scheme_id: int, player_id: int) -> void:
    if not players[player_id].active:
        return
    set_player_control_scheme(player_id, scheme_id)


func reset_players() -> void:
    players = RESET_PLAYERS


func set_player_active(player, val) -> void:
    players[player].active = val


func set_player_control_scheme(player, scheme) -> void:
    players[player].controls = scheme


func set_player_color(player, color) -> void:
    players[player].color = color


func get_movement_action_strength(player_name: String, dir: String) -> float:
    var player = players.get(player_name.to_int())
    var action_string := "{scheme}_move_{dir}".format({dir=dir})
    match player.controls:
        ControlSchemes.KBM_WASD:
            action_string = action_string.format({scheme="kb_wasd"})
        ControlSchemes.KBM_ARROW:
            action_string = action_string.format({scheme="kb_arrow"})
        ControlSchemes.JOY_0:
            action_string = action_string.format({scheme="joy0"})
        _:
            action_string = action_string.format({scheme="kb_wasd"})
    return Input.get_action_strength(action_string)


func is_action_just_pressed(player_name: String, action: String) -> bool:
    var player = players.get(player_name.to_int())
    var action_string = "{scheme}_{action}".format({action=action})
    match player.controls:
        ControlSchemes.KBM_WASD:
            action_string = action_string.format({scheme="kb_wasd"})
        ControlSchemes.KBM_ARROW:
            action_string = action_string.format({scheme="kb_arrow"})
        ControlSchemes.JOY_0:
            action_string = action_string.format({scheme="joy0"})
        _:
            action_string = action_string.format({scheme="kb_wasd"})
    return Input.is_action_just_pressed(action_string)
