extends Node


var yaml = preload("res://addons/godot-yaml/gdyaml.gdns").new()

# Names of all level scene files
var level_data: LevelDataSet

var enemy_types := {}


func load_level_data() -> void:
    self.level_data = LevelDataSet.new()
    var level_data_file = File.new()
    if level_data_file.open("res://Scenes/Levels/levels.yaml", File.READ) == OK:
        self.level_data.load_data(yaml.parse(level_data_file.get_as_text()).result)


class LevelDataSet:
    var _data = {}

    func load_data(data: Dictionary) -> void:
        self._data = data
        for level_id in self._data.levels.keys():
            self._data.levels[level_id].id = level_id
        var keys = self._data.levels.keys()
        for i in range(self._data.levels.size()):
            self._data.levels[keys[i]].index = i

    func has_level_id(id: String) -> bool:
        return self._data.levels.has(id)

    func get_num_levels() -> int:
        return self._data.levels.size()

    func get_all() -> Dictionary:
        return self._data.levels

    func get_level_by_index(index: int) -> Dictionary:
        if index >= get_num_levels():
            return {}
        return self._data.levels[(self._data.levels.keys())[index]]

    func get_level_by_id(id: String) -> Dictionary:
        for level in self._data.levels:
            if level == id:
                return self._data.levels[level]
        return {}

    func get_level_by_name(name_: String) -> Dictionary:
        for level in self._data.levels:
            if level.name == name_:
                return level
        return {}


func load_enemy_types() -> void:
    var enemy_data_file = File.new()
    if enemy_data_file.open("res://Entities/Enemies/types.yaml", File.READ) == OK:
        self.enemy_types = yaml.parse(enemy_data_file.get_as_text()).result
