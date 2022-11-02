extends Control

func _ready():
    # Called every time the node is added to the scene.
    GameState.connect("connection_failed", self, "_on_connection_failed")
    GameState.connect("connection_succeeded", self, "_on_connection_success")
    GameState.connect("player_list_changed", self, "refresh_lobby")
    GameState.connect("start_level_changed", self, "_on_start_level_changed")
    GameState.connect("game_ended", self, "_on_game_ended")
    GameState.connect("game_error", self, "_on_game_error")
    # Set the player name according to the system username. Fallback to the path.
    if OS.has_environment("USERNAME"):
        $Multiplayer/HostMenu/Name.text = OS.get_environment("USERNAME")
    else:
        var desktop_path = OS.get_system_dir(0).replace("\\", "/").split("/")
        $Multiplayer/HostMenu/Name.text = desktop_path[desktop_path.size() - 2]


func _on_host_pressed():
    print("Host!")
    if $Multiplayer/HostMenu/Name.text.strip_edges().length() == 0:
        $Multiplayer/HostMenu/ErrorLabel.text = "Invalid name!"
        return


    $Multiplayer/HostMenu.hide()
    $Multiplayer.hide()

    $Lobby.show()
    $Multiplayer/HostMenu/ErrorLabel.text = ""

    var player_name = $Multiplayer/HostMenu/Name.text
    var port = $Multiplayer/HostMenu/Port.text
    GameState.host_game(player_name, port)
    refresh_lobby()


func _on_join_pressed():
    print("Join!")
    if $Connect/Name.text == "":
        $Connect/ErrorLabel.text = "Invalid name!"
        return

    var ip = $Connect/IPAddress.text
    if not ip.is_valid_ip_address():
        $Connect/ErrorLabel.text = "Invalid IP address!"
        return

    $Connect/ErrorLabel.text = ""
    $Connect/Host.disabled = true
    $Connect/Join.disabled = true

    var player_name = $Connect/Name.text
    GameState.join_game(ip, player_name)


func _on_connection_success():
    $Connect.hide()
    $Players.show()


func _on_connection_failed():
    $Connect/Host.disabled = false
    $Connect/Join.disabled = false
    $Connect/ErrorLabel.set_text("Connection failed.")


func _on_game_ended():
    show()


func _on_game_error(errtxt):
    $ErrorDialog.dialog_text = errtxt
    $ErrorDialog.popup_centered_minsize()
    $Connect/Host.disabled = false
    $Connect/Join.disabled = false


func refresh_lobby():
    var players = GameState.players.duplicate(true)
    if not players.empty() and not players.has(1):
        print("Something went wrong, there's no server?")
        return
    var players_list: VBoxContainer = $Lobby/Players/List
    var p1 = players_list.get_node("P1")
    if players.empty():
        p1.get_node("Name").text = "%s (Host)" % GameState.player_name
        p1.get_node("Ready").pressed = GameState.player_is_ready
    else:
        p1.get_node("Name").text = "%s (Host)" % players[1].name
        p1.get_node("Ready").pressed = players[1].ready

    var p2 = players_list.get_node("P2")
    for player_id in players:
        if player_id == 1:
            continue
        p2.get_node("Name").text = "%s" % players[player_id].name
        if player_id == get_tree().get_network_unique_id():
            p2.get_node("Name").text += " (You)"
        p2.get_node("Ready").pressed = players[player_id].ready

    if get_tree().get_network_unique_id() == 1:
        p1.get_node("Ready").disabled = false
    else:
        p2.get_node("Ready").disabled = false

    $Lobby/Navbar/HBoxContainer/Start.disabled = not get_tree().is_network_server() \
        or GameState.start_level_data.size() == 0


func _on_start_pressed():
    for child in get_children():
        child.hide()
    GameState.begin_game()


func _on_find_public_ip_pressed():
    OS.shell_open("https://icanhazip.com/")


func _on_LevelSelect_pressed():
    $LevelSelect/ListContainer/LevelList.clear()
    var all_level_data = Data.level_data.get_all()
    for level in all_level_data:
        var level_name = all_level_data[level].name
        $LevelSelect/ListContainer/LevelList.add_item(level_name)
    $LevelSelect.show()
    $Players.hide()


func _on_LS_Select_pressed():
    # update current level selection
    if $LevelSelect/ListContainer/LevelList.is_anything_selected():
        var selected = $LevelSelect/ListContainer/LevelList.get_selected_items()
        var level = Data.level_data.get_level_by_index(selected[0])
        GameState.set_all_start_level(level)
    else:
        GameState.set_all_start_level(null)

    $Players/Start.disabled = GameState.start_level_data.size() == 0
    $Players.show()
    $LevelSelect.hide()


func _on_start_level_changed():
    if GameState.start_level_data.size() == 0:
        $Players/SelectedLevel.text = "Start: None"
    else:
        $Players/SelectedLevel.text = "Start: " + GameState.start_level_data.name


func _on_LS_Back_pressed():
    $Players.show()
    $LevelSelect.hide()


func _on_Exit_pressed() -> void:
    get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)


func _on_MultiPlayer_pressed() -> void:
    $MainMenu.hide()
    $Multiplayer.show()


func set_multiplayer_buttons_disabled(val: bool) -> void:
    $Multiplayer/Navbar/HBoxContainer/Host.disabled = val
    $Multiplayer/Navbar/HBoxContainer/Join.disabled = val


func _on_Host_Cancel_pressed() -> void:
    $Multiplayer/HostMenu.hide()
    set_multiplayer_buttons_disabled(false)


func _on_Multiplayer_Host_pressed() -> void:
    $Multiplayer/HostMenu.show()
    set_multiplayer_buttons_disabled(true)


func _on_Multiplayer_Back_pressed() -> void:
    set_multiplayer_buttons_disabled(false)
    $Multiplayer/HostMenu.hide()
    $Multiplayer.hide()
    $MainMenu.show()


func _on_Ready_toggled(button_pressed: bool) -> void:
    pass # Replace with function body.


func _on_Lobby_Leave_pressed() -> void:
    GameState.disconnect_from_game()
    $Lobby.hide()
    set_multiplayer_buttons_disabled(false)
    $Multiplayer.show()
