extends Node

const BRIEF_TIME = 1.0
const DEBRIEF_TIME = 1.0

# Possible level outcomes
enum Outcome { Loss = 0, Win, Error }

# Current scene camera
var camera: Camera

enum WeaponType { Primary = 0, Secondary }
