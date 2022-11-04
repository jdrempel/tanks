class_name PlayerStats extends Node


var shots = 0
var mines = 0
var deaths = 0
var team_kills = 0

var kills := {}


func _ready() -> void:
    for enemy_type in Data.enemy_types:
        kills[enemy_type] = 0


remotesync func add_kill(enemy_type: String) -> void:
    kills[enemy_type] += 1


remotesync func add_death() -> void:
    deaths += 1


remotesync func add_team_kill() -> void:
    team_kills += 1


remotesync func add_shot() -> void:
    shots += 1


remotesync func add_mine() -> void:
    mines += 1
