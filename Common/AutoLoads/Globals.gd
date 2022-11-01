extends Node

const DEBUG = false

const BRIEF_TIME = 1.0
const DEBRIEF_TIME = 1.0

# Possible level outcomes
enum Outcome { Loss = 0, Win, Error }

# Current scene camera
var camera: Camera

enum WeaponType { Primary = 0, Secondary }


func random_point_on_circle(origin: Vector3, radius: float) -> Vector3:
    return Vector3(radius * cos(randf() * 2 * PI), 0, radius * sin(randf() * 2 * PI))
