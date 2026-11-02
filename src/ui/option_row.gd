class_name OptionRow
extends Button
# One setting on the options screen: its name on the left and its value on the right, as a row of
# notches for 0-10 numbers or On / Off for toggles. Left and right change a number; A, left or right
# flip a toggle. Changes go straight to Settings, which applies and saves them.

const NOTCH_WIDTH := 22.0
const NOTCH_GAP := 6.0

var key: String

func _init(label: String, setting_key: String) -> void:
	key = setting_key
	name = setting_key.to_pascal_case()
	text = label
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	custom_minimum_size = Vector2(760, 58)
	add_theme_font_override("font", UiTheme.body_font("Medium"))
	add_theme_font_size_override("font_size", 32)
	focus_entered.connect(func() -> void: Sound.play("focus"))
	pressed.connect(func() -> void:
		if Settings.is_toggle(key):
			_flip())

func _gui_input(event: InputEvent) -> void:
	for step in [-1, 1]:
		if event.is_action_pressed("ui_left" if step < 0 else "ui_right", true):
			accept_event()
			if Settings.is_toggle(key):
				_flip()
			else:
				_nudge(step)

func _nudge(step: int) -> void:
	var before: int = Settings.get_value(key)
	Settings.set_value(key, before + step)
	if Settings.get_value(key) == before:
		Sound.play("denied", 1.0, -6.0)
	else:
		Sound.play("tick", 0.8 + 0.05 * Settings.get_value(key))
	queue_redraw()

func _flip() -> void:
	Settings.set_value(key, not Settings.get_value(key))
	Sound.play("tick")
	queue_redraw()

func _draw() -> void:
	var lit := has_focus()
	var value: Variant = Settings.get_value(key)
	var right := size.x - 28.0
	var middle := size.y * 0.5
	if value is bool:
		var font := UiTheme.body_font("Bold")
		var word := "On" if value else "Off"
		var width := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
		var colour := (UiTheme.GOLD if lit else UiTheme.PARCHMENT) if value else UiTheme.FADED
		draw_string(font, Vector2(right - width, middle + 11), word, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, colour)
		return
	var largest: int = Settings.LIMITS[key].largest
	var left := right - largest * (NOTCH_WIDTH + NOTCH_GAP) + NOTCH_GAP
	for i in largest:
		var on: bool = i < value
		var height := 12.0 + 16.0 * i / (largest - 1)
		var notch := Rect2(left + i * (NOTCH_WIDTH + NOTCH_GAP), middle + 14 - height, NOTCH_WIDTH, height)
		var colour := (UiTheme.GOLD if lit else UiTheme.PARCHMENT) if on else Color(UiTheme.FADED, 0.25)
		draw_rect(notch, colour)
