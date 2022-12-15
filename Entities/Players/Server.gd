extends Node

var player: Player


func initialize(player_node: Player) -> void:
    self.player = player_node


func _physics_process(delta):
    if player.paused:
        return
    send_player_state()


func send_player_state() -> void:
    var player_state = player.get_player_state()
    rpc_unreliable("receive_player_state", player_state)


remote func receive_player_state(player_state: Dictionary) -> void:
    player.set_player_state(player_state)


func send_player_attack(weapon_name: String) -> void:
    pass
