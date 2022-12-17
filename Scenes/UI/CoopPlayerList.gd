extends VBoxContainer


func _ready() -> void:
    refresh()


func refresh() -> void:
	return
	var joypads = Input.get_connected_joypads()
	for player_num in range(joypads.size()):
		get_node("P%d" % (player_num + 2)).free()
