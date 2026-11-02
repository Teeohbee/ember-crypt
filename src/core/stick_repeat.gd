class_name StickRepeat
extends RefCounted
# Turns a held stick into menu presses the way a held D-pad repeats: one press the moment it's pushed,
# then after a pause, a steady stream. Changing direction presses straight away.

const FIRST_DELAY := 0.4
const REPEAT_EVERY := 0.11

var _held := Vector2i.ZERO
var _wait := 0.0

# The direction the stick points this frame (zero when centred); returns the direction to press now,
# or zero.
func update(direction: Vector2i, delta: float) -> Vector2i:
	if direction == Vector2i.ZERO:
		_held = Vector2i.ZERO
		return Vector2i.ZERO
	if direction != _held:
		_held = direction
		_wait = FIRST_DELAY
		return direction
	_wait -= delta
	if _wait <= 0.0:
		_wait += REPEAT_EVERY
		return direction
	return Vector2i.ZERO

# The stick as one of four directions, or zero inside the deadzone. Whichever axis is pushed further wins.
static func direction_of(stick: Vector2, deadzone := 0.5) -> Vector2i:
	if stick.length() < deadzone:
		return Vector2i.ZERO
	if absf(stick.x) > absf(stick.y):
		return Vector2i(int(signf(stick.x)), 0)
	return Vector2i(0, int(signf(stick.y)))
