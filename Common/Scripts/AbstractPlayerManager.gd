class_name AbstractPlayerManager
extends Node


var type := 0
var peer = null

var players := {}


func host_game(_player_name: String = "", _port: String = "") -> void:
    pass


func _on_control_scheme_changed(player_id: int, scheme_id: int) -> void:
    if not players[player_id].active:
        return
    set_player_control_scheme(player_id, scheme_id)


func reset_players() -> void:
    players = {}


func set_player_active(player, val) -> void:
    players[player].active = val


func set_player_control_scheme(player, scheme) -> void:
    players[player].controls = scheme


func set_player_color(player_id: int, color_str: String) -> void:
    players[player_id].set_color(color_str)


func set_all_start_level(level_id: String) -> void:
    rpc_id(0, "request_start_level_change", level_id)


puppet func request_start_level_change(level_id: String) -> void:
    Globals.menus.set_remote_start_level(level_id)
