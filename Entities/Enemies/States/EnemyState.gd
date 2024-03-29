extends State

class_name EnemyState

var enemy: Enemy


func _ready() -> void:
    yield(owner, "ready")
    enemy = owner as Enemy
    assert(enemy != null)
    enemy.connect("pause_changed", self, "set_paused")
