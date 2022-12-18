class_name CoopPlayerManager
extends AbstractPlayerManager


enum PlayerIds { P1 = 0, P2, P3, P4 }


func _ready() -> void:
    type = Globals.PlayerManagers.COOP

    players[PlayerIds.P1] = PlayerData.new().initialize(PlayerIds.P1, "P1", true,
        true, "Blue", Globals.ControlSchemes.KBM_WASD)
    players[PlayerIds.P2] = PlayerData.new().initialize(PlayerIds.P2, "P2", true,
        true, "Red", Globals.ControlSchemes.JOY_0)


func host_game(_player_name: String = "", _port: String = "") -> void:
    peer = NetworkedMultiplayerENet.new()
    peer.create_server(Globals.DEFAULT_PORT, 1)
    get_tree().set_network_peer(peer)
