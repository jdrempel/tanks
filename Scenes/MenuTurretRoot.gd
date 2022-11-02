extends Spatial


export var turn_magnitude := 2.0
export var turn_speed := 0.02

var random_init_rotation: float


func _ready() -> void:
    randomize()
    random_init_rotation = randf() * 2 * PI
    rotate_y(random_init_rotation)


func _physics_process(delta: float) -> void:
    rotate_y(turn_magnitude * delta * cos(turn_speed * delta * OS.get_system_time_msecs()))
