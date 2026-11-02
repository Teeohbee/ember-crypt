class_name Flicker
extends Light3D
# Firelight: the energy wanders on two slow noise curves and a fast one, so no two torches pulse in
# step and none of them looks like a sine wave. Set up from whatever energy the light starts with.

var _base := 0.0
var _time := 0.0
var _noise := FastNoiseLite.new()

func _ready() -> void:
	_base = light_energy
	_noise.seed = randi()
	_noise.frequency = 1.0
	_time = randf() * 100.0

func _process(delta: float) -> void:
	_time += delta
	var slow := _noise.get_noise_1d(_time * 0.9) * 0.18
	var fast := _noise.get_noise_1d(_time * 7.0 + 50.0) * 0.08
	light_energy = _base * (1.0 + slow + fast)
