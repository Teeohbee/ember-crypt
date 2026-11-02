class_name GameCamera
extends Camera3D
# The ARPG camera: a fixed angle that never rotates, following the middle of every hero (a list of one
# until co-op) with a little lag.

# About 50 degrees down, low enough to see the walls you're walking toward, close enough to read a
# skeleton's face
const OFFSET := Vector3(0, 11.0, 9.5)
const FOLLOW := 6.0

func _init() -> void:
	name = "GameCamera"
	fov = 44.0

func _ready() -> void:
	snap()

func focus() -> Vector3:
	var heroes := Session.heroes()
	if heroes.is_empty():
		return global_position - OFFSET
	var middle := Vector3.ZERO
	for hero in heroes:
		middle += hero.global_position
	return middle / heroes.size()

func snap() -> void:
	var target := focus()
	global_position = target + OFFSET
	look_at(target + Vector3(0, 1.0, 0))

func _process(delta: float) -> void:
	global_position = global_position.lerp(focus() + OFFSET, 1.0 - exp(-FOLLOW * delta))
