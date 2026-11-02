class_name Shove
extends Node
# Moves a body by an offset over a short time, easing out and sliding to a stop against anything solid.
# Knockback and the melee step-lunge both use it. It moves the body with move_and_collide, beside
# whatever drives its velocity, so a monster brain and a shove never fight over the same number.

var body: CharacterBody3D
var _offset := Vector3.ZERO
var _duration := 0.0
var _elapsed := 0.0

# Starts (or restarts) the body's shove, adding the node the first time
static func apply(target: CharacterBody3D, offset: Vector3, seconds: float) -> Shove:
	var shove := target.get_node_or_null(^"Shove") as Shove
	if shove == null:
		shove = Shove.new()
		shove.name = "Shove"
		target.add_child(shove)
	shove.start(offset, seconds)
	return shove

func _ready() -> void:
	body = get_parent() as CharacterBody3D

func start(offset: Vector3, seconds: float) -> void:
	offset.y = 0.0
	_offset = offset
	_duration = maxf(seconds, 0.01)
	_elapsed = 0.0
	set_physics_process(true)

func moving() -> bool:
	return _elapsed < _duration

func _physics_process(delta: float) -> void:
	if not moving() or body == null:
		set_physics_process(false)
		return
	var before := _eased(_elapsed / _duration)
	_elapsed = minf(_elapsed + delta, _duration)
	var step := _offset * (_eased(_elapsed / _duration) - before)
	if body.move_and_collide(step) != null:
		# Hit a wall or another body: the rest of the shove is spent
		_elapsed = _duration

static func _eased(t: float) -> float:
	return 1.0 - (1.0 - t) * (1.0 - t)
