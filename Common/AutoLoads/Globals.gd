extends Node

# Names of all level scene files
var levels = []

# Current scene camera
var camera: Camera

enum WeaponType { Primary, Secondary }

class PlayerStats:

    var index: int
    var name: String

    var num_deaths: int
    var num_kills: int


func get_all_level_files():
    var files = []
    var levels_dir = Directory.new()
    levels_dir.open("res://Scenes/Levels")
    levels_dir.list_dir_begin()

    while true:
        var file = levels_dir.get_next()
        if file == "":
            break
        elif not levels_dir.current_is_dir():
            files.append(file)

    levels_dir.list_dir_end()

    files.sort()
    self.levels = files
