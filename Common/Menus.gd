extends Control


func _ready():
    Multiplayer.connect("connection_failed", self, "_on_connection_failed")
    Multiplayer.connect("connection_succeeded", self, "_on_connection_success")
    Multiplayer.connect("player_list_changed", self, "refresh_lobby")
    Multiplayer.connect("server_disconnected", self, "_on_server_disconnect")
    Multiplayer.connect("all_players_ready", self, "_on_all_players_ready")
    Multiplayer.connect("player_unready", self, "_on_player_unready")

    GameState.connect("game_ended", self, "_on_game_ended")
    GameState.connect("game_error", self, "_on_game_error")

    $Lobby/Levels/ScrollContainer/LevelContainer.connect("selection_changed",
        self, "_on_start_level_changed")
    $Lobby/PlayerColor/Colors.connect("selection_changed", self, "_on_player_color_changed")

    # Set the player name according to the system username. Fallback to the path.
    if OS.has_environment("USERNAME"):
        $Multiplayer/HostMenu/Name.text = OS.get_environment("USERNAME")
        $Multiplayer/JoinMenu/Name.text = OS.get_environment("USERNAME")
    else:
        var desktop_path = OS.get_system_dir(0).replace("\\", "/").split("/")
        $Multiplayer/HostMenu/Name.text = desktop_path[desktop_path.size() - 2]
        $Multiplayer/JoinMenu/Name.text = desktop_path[desktop_path.size() - 2]

    Globals.menus = self

    var crosshair = preload("res://CrosshairTexture.tres")
    Input.set_custom_mouse_cursor(crosshair, Input.CURSOR_ARROW, Vector2(16, 16))

    if Data.enemy_types.empty():
        print("Enemy types haven't been loaded yet!")

    for enemy_type in Data.enemy_types:
        var tank_icon = TextureRect.new()
        tank_icon.texture = preload("res://icon.png")
        tank_icon.expand = true
        tank_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        tank_icon.rect_min_size = Vector2(32, 32)
        tank_icon.size_flags_horizontal = SIZE_SHRINK_CENTER

        tank_icon.modulate = Color(Data.enemy_types[enemy_type])
        $Stats/List/Labels.add_child(tank_icon)

        var p1_entry = Label.new()
        p1_entry.align = Label.ALIGN_CENTER
        p1_entry.valign = Label.VALIGN_CENTER
        p1_entry.name = enemy_type
        p1_entry.text = "0"
        p1_entry.rect_min_size = Vector2(32, 32)
        $Stats/List/P1.add_child(p1_entry)

        var p2_entry = p1_entry.duplicate(0)
        $Stats/List/P2.add_child(p2_entry)

    $Background.global_translate(Vector3(0, -1000, 0))


func toggle_pause_menu(val: bool) -> void:
    if val:
        $PauseMenu.show()
    else:
        $PauseMenu.hide()


func hide_all() -> void:
    for child in get_children():
        child.hide()


func refresh_level_availability() -> void:
    if not get_tree().is_network_server():
        $Lobby/Levels/ScrollContainer/LevelContainer.disable_all()
    else:
        var disable_now = false
        for level_id in Data.level_data.get_all():
            var index = Data.level_data.get_index_by_id(level_id)
            if index > GameState.last_checkpoint and index != 1:
                $Lobby/Levels/ScrollContainer/LevelContainer.disable_level(level_id)
            else:
                $Lobby/Levels/ScrollContainer/LevelContainer.enable_level(level_id)


func refresh_lobby():
    var players = Multiplayer.players.duplicate(true)
    if not players.empty() and not players.has(1):
        print("There's no server (yet)?")
        return

    var players_list: VBoxContainer = $Lobby/Players/List
    var p1 = players_list.get_node("P1")
    var p2 = players_list.get_node("P2")
    var p_node: Control
    for player_id in players:
        if player_id == 1:
            p_node = p1
        else:
            p_node = p2
        p_node.get_node("Name").text = players[player_id].name
        if player_id == 1:
            p_node.get_node("Name").text += " (Host)"
        if player_id == get_tree().get_network_unique_id():
            p_node.get_node("Name").text += " (You)"
        p_node.get_node("Ready").pressed = players[player_id].ready

    if players.size() < 2:
        p2.get_node("Name").text = "Waiting for player..."
        p2.get_node("Ready").pressed = false

    if get_tree().get_network_unique_id() == 1:
        p1.get_node("Ready").disabled = false
    else:
        p2.get_node("Ready").disabled = false

    $Lobby/Navbar/HBoxContainer/Start.disabled = not get_tree().is_network_server() \
        or GameState.start_level_data.empty() or not Multiplayer.check_all_players_ready()

    refresh_level_availability()


func _on_host_pressed():
    print("Host!")

    var host_menu = $Multiplayer/HostMenu
    var player_name_field = host_menu.get_node("Name")
    var error_field = host_menu.get_node("ErrorLabel")
    var port_field = host_menu.get_node("Port")

    if player_name_field.text.strip_edges().length() == 0:
        error_field.text = "Invalid name!"
        return

    host_menu.hide()
    $Multiplayer.hide()

    $Lobby.show()
    error_field.text = ""

    var player_name = player_name_field.text
    var port = port_field.text
    Multiplayer.host_game(player_name, port)
    $Lobby/PlayerColor/Colors._on_child_selected($Lobby/PlayerColor/Colors.get_node("Blue"))

    refresh_lobby()


func _on_join_pressed():
    print("Join!")

    var join_menu = $Multiplayer/JoinMenu
    var player_name_field = join_menu.get_node("Name")
    var error_field = join_menu.get_node("ErrorLabel")
    var ip_field = join_menu.get_node("HBoxContainer2/Address")
    var port_field = join_menu.get_node("HBoxContainer2/Port")
    var join_button = join_menu.get_node("HBoxContainer/Join")

    if player_name_field.text == "":
        error_field.text = "Invalid name!"
        return

    var ip = ip_field.text
    if ip.length() == 0:
        ip = "127.0.0.1"
    if not ip.is_valid_ip_address():
        error_field.text = "Invalid IP address!"
        return

    var port = port_field.text
    if port.length() == 0:
        port = "1337"
    if not port.to_int() > 0 or not port.to_int() <= 65535:
        error_field.text = "Invalid port (must be 0-65535)!"
        return

    error_field.text = ""
    join_button.disabled = true

    var player_name = player_name_field.text
    Multiplayer.join_game(ip, port, player_name)

    refresh_lobby()


func _on_connection_success():
    $Multiplayer/JoinMenu/HBoxContainer/Join.disabled = false
    $Multiplayer/JoinMenu.hide()
    $Multiplayer.hide()
    set_multiplayer_buttons_disabled(false)
    $Lobby.show()


func _on_connection_failed():
    $Multiplayer/JoinMenu/HBoxContainer/Join.disabled = false
    $Multiplayer/JoinMenu/ErrorLabel.set_text("Connection failed.")


func _on_server_disconnect():
    show()
    $Lobby.hide()
    $Multiplayer.show()


func _on_game_ended(outcome: int, player_stats: Array) -> void:
    if get_tree().is_network_server():
        $Lobby/Players/List/P1/Ready.pressed = false
    else:
        $Lobby/Players/List/P2/Ready.pressed = false
    Multiplayer.set_lobby_player_ready(false)
    for player in player_stats:
        var player_id = player.get_name().to_int()
        var player_name = Multiplayer.players[player_id].name
        var player_node
        if player.get_name().to_int() == 1:
            player_node = $Stats/List/P1
        else:
            player_node = $Stats/List/P2
        player_node.get_node("Label").text = player_name
        player_node.get_node("Shots").text = str(player.shots)
        player_node.get_node("Mines").text = str(player.mines)
        player_node.get_node("Deaths").text = str(player.deaths)
        player_node.get_node("TeamKills").text = str(player.team_kills)
        for enemy_type in player.kills:
            player_node.get_node(enemy_type).text = str(player.kills[enemy_type])

    if outcome == Globals.Outcome.Win:
        $Stats/Outcome.text = "Victory!"
    else:
        $Stats/Outcome.text = "Defeat"

    var black = preload("res://Scenes/UI/FadeBlack.tscn").instance()
    add_child(black)
    black.fade_from_black()
    $Stats.show()
    show()
    $Background/Camera.current = true


func _on_game_error(error_text: String) -> void:
    GameState.reset()
    $ErrorDialog.dialog_text = error_text
    $ErrorDialog.popup_centered_minsize()
    set_multiplayer_buttons_disabled(false)


func _on_Start_pressed():
    # Single-player
    GameState.begin_game()


func _on_find_public_ip_pressed():
    OS.shell_open("https://icanhazip.com/")


func _on_start_level_changed(level_id: String) -> void:
    var level = Data.level_data.get_level_by_id(level_id)
    GameState.set_all_start_level(level)
    Multiplayer.set_all_start_level(level_id)


func set_remote_start_level(level_id: String) -> void:
    $Lobby/Levels/ScrollContainer/LevelContainer.set_selection(level_id)


func _on_player_color_changed(color_name: String) -> void:
    Multiplayer.set_lobby_player_color(color_name)


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


func _on_Multiplayer_Join_pressed() -> void:
    $Multiplayer/JoinMenu.show()
    set_multiplayer_buttons_disabled(true)


func _on_Multiplayer_Back_pressed() -> void:
    set_multiplayer_buttons_disabled(false)
    $Multiplayer/HostMenu.hide()
    $Multiplayer/JoinMenu.hide()
    $Multiplayer.hide()
    $MainMenu.show()


func _on_P1_Ready_toggled(button_pressed: bool) -> void:
    if not get_tree().is_network_server():
        return
    Multiplayer.set_lobby_player_ready(button_pressed)


func _on_P2_Ready_toggled(button_pressed: bool) -> void:
    if get_tree().is_network_server():
        return
    Multiplayer.set_lobby_player_ready(button_pressed)


func _on_Lobby_Start_pressed() -> void:
    $Lobby.hide()
    $Background.hide()
    $Background/Camera.current = false
    GameState.begin_game()


func _on_Lobby_Leave_pressed() -> void:
    Multiplayer.disconnect_from_game()
    $Multiplayer/JoinMenu/HBoxContainer/Join.disabled = false
    $Lobby.hide()
    set_multiplayer_buttons_disabled(false)
    $Multiplayer.show()


func _on_all_players_ready() -> void:
    if get_tree().is_network_server():
        $Lobby/Navbar/HBoxContainer/Start.disabled = false


func _on_player_unready() -> void:
    if get_tree().is_network_server():
        $Lobby/Navbar/HBoxContainer/Start.disabled = true


func _on_Join_Cancel_pressed() -> void:
    $Multiplayer/JoinMenu.hide()
    set_multiplayer_buttons_disabled(false)


func _on_Stats_Lobby_pressed() -> void:
    $Stats.hide()
    $Background.show()
    $Background/Camera.current = true
    $Lobby.show()


func _on_pause_pressed() -> void:
    if $PauseMenu.visible:
        $PauseMenu.hide()
    else:
        $PauseMenu.show()
