extends Control
# A moment of black and a byline before the title. Any button skips it.

const FRONT_END := "res://src/frontend/front_end.tscn"

var _leaving := false

func _ready() -> void:
	var black := ColorRect.new()
	black.color = UiTheme.VOID
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(black)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 10)
	column.modulate.a = 0.0
	add_child(column)
	column.add_child(UiTheme.heading("a game by", 26, UiTheme.FADED))
	column.add_child(UiTheme.heading("Toby Clarke", 54, UiTheme.PARCHMENT))
	var tween := create_tween()
	tween.tween_interval(0.4)
	tween.tween_property(column, "modulate:a", 1.0, 0.9)
	tween.tween_interval(1.4)
	tween.tween_property(column, "modulate:a", 0.0, 0.8)
	tween.tween_callback(_leave)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo() and not event is InputEventJoypadMotion:
		_leave()

func _leave() -> void:
	if not _leaving:
		_leaving = true
		SceneManager.go_to(FRONT_END)
