class_name StatsManager
extends Node


var stats := {}


func add_player_stats_container(player_id: int) -> void:
    stats[player_id] = PlayerStats.new()

func add_player_kill(player_id: int, type: String) -> void:
    stats[player_id].add_kill(type)

func add_player_death(player_id: int) -> void:
    stats[player_id].add_death()

func add_team_kill(player_id: int) -> void:
    stats[player_id].add_team_kill()

func add_player_shot(player_id: int) -> void:
    stats[player_id].add_shot()

func add_player_mine(player_id: int) -> void:
    stats[player_id].add_mine()
