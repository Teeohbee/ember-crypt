class_name MenuList
extends VBoxContainer
# A column of menu buttons. Focus wraps from the bottom to the top, greyed-out items are skipped, every
# move ticks and every choice tolls. take_focus() goes back to whatever was last chosen, so stepping
# back out of a screen lands where you went in, and it's quiet, so opening a menu doesn't click.

var _quiet := false
var _last_chosen: Button

func _init() -> void:
	add_theme_constant_override("separation", 6)

func add_item(label: String, on_choose: Callable, enabled := true) -> Button:
	var button := Button.new()
	button.text = label
	button.name = label.to_pascal_case()
	button.disabled = not enabled
	button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.focus_entered.connect(func() -> void:
		if not _quiet:
			Sound.play("focus"))
	button.pressed.connect(func() -> void:
		_last_chosen = button
		Sound.play("confirm")
		on_choose.call())
	add_child(button)
	_link()
	return button

func take_focus() -> void:
	var enabled := _enabled()
	if enabled.is_empty():
		return
	_quiet = true
	(_last_chosen if _last_chosen in enabled else enabled[0]).grab_focus()
	_quiet = false

# Back to the top, forgetting the last choice: for a menu opened afresh
func reset() -> void:
	_last_chosen = null

func _enabled() -> Array[Button]:
	var found: Array[Button] = []
	for child in get_children():
		if child is Button and not child.disabled:
			found.append(child)
	return found

# Up and down go to the next enabled item, wrapping round, and left and right go nowhere.
func _link() -> void:
	var buttons := _enabled()
	for i in buttons.size():
		var button := buttons[i]
		button.focus_neighbor_top = button.get_path_to(buttons[i - 1])
		button.focus_neighbor_bottom = button.get_path_to(buttons[(i + 1) % buttons.size()])
		button.focus_neighbor_left = button.get_path_to(button)
		button.focus_neighbor_right = button.get_path_to(button)
