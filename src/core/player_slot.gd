class_name PlayerSlot
extends RefCounted
# One player: the pad they hold and the hero that's theirs. Every gameplay input read goes through a
# slot, never straight to Input, so co-op is a second slot rather than a rewrite. Until co-op the one
# slot listens to every device (-1) and to the keyboard.

const STICK_DEADZONE := 0.2

var index := 0
var device := -1
var hero: Hero

func _init(slot_index := 0, device_id := -1) -> void:
	index = slot_index
	device = device_id

# Left stick, or WASD / arrows. Length 0-1, deadzone removed.
func move_vector() -> Vector2:
	var keys := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var stick := _stick(JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y)
	return stick if stick.length() > keys.length() else keys

# Right stick, deadzone removed
func aim_vector() -> Vector2:
	return _stick(JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y)

func pressed(action: StringName) -> bool:
	return Input.is_action_pressed(action)

func just_pressed(action: StringName) -> bool:
	return Input.is_action_just_pressed(action)

func just_released(action: StringName) -> bool:
	return Input.is_action_just_released(action)

func _stick(x_axis: JoyAxis, y_axis: JoyAxis) -> Vector2:
	var best := Vector2.ZERO
	var pads := Input.get_connected_joypads() if device < 0 else [device]
	for pad: int in pads:
		var stick := Vector2(Input.get_joy_axis(pad, x_axis), Input.get_joy_axis(pad, y_axis))
		if stick.length() > best.length():
			best = stick
	if best.length() < STICK_DEADZONE:
		return Vector2.ZERO
	return best.normalized() * remap(minf(best.length(), 1.0), STICK_DEADZONE, 1.0, 0.0, 1.0)
