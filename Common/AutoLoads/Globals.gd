extends Node

const DEBUG = true

var input_delay_ms = 100.0

# Time spent in level briefing/debriefing
const BRIEF_TIME = 2.0
const DEBRIEF_TIME = 2.0

# Time it takes to fade in and out of black between levels
const FADE_TIME = 0.8

# Checkpoint constants
# Interval between level checkpoints during a play-through
const CHECKPOINT_INTERVAL = 5

# Possible level outcomes
enum Outcome { Loss = 0, Win, Error }

# Current scene camera
var camera: Camera

enum WeaponType { Primary = 0, Secondary }

# Menus node
var menus: Control


func random_point_on_circle(origin: Vector3, radius: float) -> Vector3:
    return origin + Vector3(radius * cos(randf() * 2 * PI), 0, radius * sin(randf() * 2 * PI))
