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
        $Connect/Name.text = OS.get_environment("USERNAME")
    else:
        var desktop_path = OS.get_system_dir(0).replace("\\", "/").split("/")
        $Connect/Name.text = desktop_path[desktop_path.size() - 2]


func _on_host_pressed():
    print("host!")
    if $Connect/Name.text == "":
        $Connect/ErrorLabel.text = "Invalid name!"
        return

    $Connect.hide()
    $Players.show()
    $Connect/ErrorLabel.text = ""

    var player_name = $Connect/Name.text
    GameState.host_game(player_name)
    refresh_lobby()


func _on_join_pressed():
    print("join!")
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
    $Connect.hide()
    $Players.show()


func _on_game_error(errtxt):
    $ErrorDialog.dialog_text = errtxt
    $ErrorDialog.popup_centered_minsize()
    $Connect/Host.disabled = false
    $Connect/Join.disabled = false


func refresh_lobby():
    var players = GameState.players.values()
    players.sort()
    $Players/List.clear()
    $Players/List.add_item(GameState.player_name + " (You)")
    for p in players:
        $Players/List.add_item(p)

    $Players/Start.disabled = not get_tree().is_network_server() \
        or GameState.start_level_data.size() == 0
    $Players/LevelSelect.disabled = not get_tree().is_network_server()


func _on_start_pressed():
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
