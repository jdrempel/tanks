extends Node


var player_manager
var control_manager
var stats_manager


func _ready() -> void:
    control_manager = ControlManager.new()


func set_player_manager(type: int) -> void:
    var new_player_manager
    match type:
        Globals.PlayerManagers.COOP:
            new_player_manager = CoopPlayerManager.new()
        Globals.PlayerManagers.ONLINE:
            new_player_manager = OnlinePlayerManager.new()
        _:
            pass
    if is_instance_valid(player_manager):
        remove_child(player_manager)
    add_child(new_player_manager)
    player_manager = new_player_manager
