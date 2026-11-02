extends Node
# The input map, built here rather than in project.godot so it reads as one table. Gameplay actions
# match any device for now; when co-op arrives each hero's PlayerSlot filters events by device id.
#
# Menus move on the D-pad, and on the left stick through StickRepeat: Godot would read every stick
# motion event past the deadzone as a fresh press, which skips three rows at a time.

# SDL / Xbox layout button indices
const A := JOY_BUTTON_A
const B := JOY_BUTTON_B
const X := JOY_BUTTON_X
const Y := JOY_BUTTON_Y

# Each action: its keys and pad buttons. Triggers are axes, so they're listed separately.
const ACTIONS := {
	"ui_accept": {"keys": [KEY_ENTER, KEY_SPACE], "buttons": [A]},
	"ui_cancel": {"keys": [KEY_ESCAPE, KEY_BACKSPACE], "buttons": [B]},
	"ui_up": {"keys": [KEY_UP, KEY_W], "buttons": [JOY_BUTTON_DPAD_UP]},
	"ui_down": {"keys": [KEY_DOWN, KEY_S], "buttons": [JOY_BUTTON_DPAD_DOWN]},
	"ui_left": {"keys": [KEY_LEFT, KEY_A], "buttons": [JOY_BUTTON_DPAD_LEFT]},
	"ui_right": {"keys": [KEY_RIGHT, KEY_D], "buttons": [JOY_BUTTON_DPAD_RIGHT]},
	"tab_previous": {"keys": [KEY_Q], "buttons": [JOY_BUTTON_LEFT_SHOULDER]},
	"tab_next": {"keys": [KEY_E], "buttons": [JOY_BUTTON_RIGHT_SHOULDER]},
	"pause": {"keys": [KEY_ESCAPE], "buttons": [JOY_BUTTON_START]},
	"inventory": {"keys": [KEY_I, KEY_TAB], "buttons": [JOY_BUTTON_BACK]},
	"skills_menu": {"keys": [KEY_P], "buttons": [JOY_BUTTON_DPAD_LEFT]},
	"menu_delete": {"keys": [KEY_DELETE, KEY_X], "buttons": [X]},
	"skill_1": {"keys": [KEY_J], "buttons": [A]},
	"skill_2": {"keys": [KEY_K], "buttons": [X]},
	"skill_3": {"keys": [KEY_L], "buttons": [Y]},
	"skill_4": {"keys": [KEY_SEMICOLON], "buttons": [B]},
	"skill_5": {"keys": [KEY_U], "buttons": [JOY_BUTTON_RIGHT_SHOULDER]},
	"skill_6": {"keys": [KEY_O], "triggers": [JOY_AXIS_TRIGGER_RIGHT]},
	"potion": {"keys": [KEY_Q], "buttons": [JOY_BUTTON_LEFT_SHOULDER]},
	"target_lock": {"keys": [KEY_SHIFT], "triggers": [JOY_AXIS_TRIGGER_LEFT]},
	# The evade is the right stick (read through PlayerSlot.aim_vector); this is its debug key
	"evade": {"keys": [KEY_C]},
	# M4: hold to wear what you just picked up
	"equip": {"keys": [KEY_F], "buttons": [JOY_BUTTON_DPAD_UP]},
}

const UI_DIRECTIONS := {Vector2i.UP: "ui_up", Vector2i.DOWN: "ui_down", Vector2i.LEFT: "ui_left", Vector2i.RIGHT: "ui_right"}

var _stick := StickRepeat.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	build_input_map()

static func build_input_map() -> void:
	for action: String in ACTIONS:
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
		else:
			InputMap.add_action(action, 0.5)
		var spec: Dictionary = ACTIONS[action]
		for key: Key in spec.get("keys", []):
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
		for button: JoyButton in spec.get("buttons", []):
			var event := InputEventJoypadButton.new()
			event.device = -1
			event.button_index = button
			InputMap.action_add_event(action, event)
		for axis: JoyAxis in spec.get("triggers", []):
			var event := InputEventJoypadMotion.new()
			event.device = -1
			event.axis = axis
			event.axis_value = 1.0
			InputMap.action_add_event(action, event)

func _process(delta: float) -> void:
	var stick := Vector2.ZERO
	for device in Input.get_connected_joypads():
		var this_pad := Vector2(Input.get_joy_axis(device, JOY_AXIS_LEFT_X), Input.get_joy_axis(device, JOY_AXIS_LEFT_Y))
		if this_pad.length() > stick.length():
			stick = this_pad
	var press := _stick.update(StickRepeat.direction_of(stick), delta)
	if press != Vector2i.ZERO:
		_press(UI_DIRECTIONS[press])

func _press(action: String) -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
