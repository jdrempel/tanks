extends Camera

export var orbit_speed := 1.0
export var orbit_height := 1.5
export var orbit_radius := 1.2


func _ready() -> void:
    global_transform.origin = Vector3(0, orbit_height-1000, orbit_radius)


func _physics_process(delta: float) -> void:
    look_at_from_position(
        Vector3(
            orbit_radius*cos(OS.get_system_time_msecs() * delta * orbit_speed),
            orbit_height-1000,
            orbit_radius*sin(OS.get_system_time_msecs() * delta * orbit_speed)),
        Vector3(0, -1000, 0),
        Vector3.UP)
