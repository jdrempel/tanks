extends Camera

export var decay = 1.5
export var max_offset = Vector2(0.1, 0.05)
export var max_roll = 0.1

onready var noise = OpenSimplexNoise.new()
var noise_y = 0

var trauma = 0.0
var trauma_power = 2


func _ready() -> void:
    randomize()
    noise.seed = randi()
    noise.period = 4
    noise.octaves = 2
    Globals.camera = self
    current = true


func add_trauma(amount):
    trauma = min(trauma + amount, 1.0)


func _process(delta: float) -> void:
    if trauma:
        trauma = max(trauma - decay * delta, 0)
        shake()


func shake() -> void:
    var amount = pow(trauma, trauma_power)
    noise_y += 1
    h_offset = max_offset.x * amount * noise.get_noise_2d(noise.seed * 2, noise_y)
    v_offset = max_offset.y * amount * noise.get_noise_2d(noise.seed * 3, noise_y)
