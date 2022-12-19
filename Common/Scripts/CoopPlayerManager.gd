class_name CoopPlayerManager
extends AbstractPlayerManager


enum PlayerIds { P1 = 0, P2, P3, P4 }


func _ready() -> void:
    type = Globals.PlayerManagers.COOP

    players[PlayerIds.P1] = PlayerData.new().initialize(PlayerIds.P1, "P1", true,
        true, "Blue", Globals.PLAYER_DEFAULT_SCHEME_MAP["P1"])
    players[PlayerIds.P2] = PlayerData.new().initialize(PlayerIds.P2, "P2", true,
        true, "Red", Globals.PLAYER_DEFAULT_SCHEME_MAP["P2"])


func host_game(_player_name: String = "", _port: String = "") -> void:
    peer = NetworkedMultiplayerENet.new()
    peer.create_server(Globals.DEFAULT_PORT, 1)
    get_tree().set_network_peer(peer)


func set_player_network_master(player_id: int, new_master: int) -> void:
    if not is_instance_valid(GameState.current_level):
        return

    var player_node: Node = GameState.current_level.get_node("Players/%d" % player_id)
    if not is_instance_valid(player_node):
        return

    player_node.set_network_master(1)
