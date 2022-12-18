extends Node

const DEBUG = true

# Max number of players.
const MAX_PEERS = 2
# Multiplayer default port
const DEFAULT_PORT = 1337

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

# Possible player managers
enum PlayerManagers { NONE = -1, SOLO, COOP, ONLINE }

# Control schemes
enum ControlSchemes { NONE = -1, KBM_WASD, KBM_ARROW, JOY_0, JOY_1 }
const SCHEME_TO_NAME_MAP = {
    ControlSchemes.NONE: "kb_wasd",  # default
    ControlSchemes.KBM_WASD: "kb_wasd",
    ControlSchemes.KBM_ARROW: "kb_arrow",
    ControlSchemes.JOY_0: "joy0",
    ControlSchemes.JOY_1: "joy1",
   }

# Current scene camera
var camera: Camera

enum WeaponType { Primary = 0, Secondary }

# Menus node
var menus: Control


func random_point_on_circle(origin: Vector3, radius: float) -> Vector3:
    return origin + Vector3(radius * cos(randf() * 2 * PI), 0, radius * sin(randf() * 2 * PI))
