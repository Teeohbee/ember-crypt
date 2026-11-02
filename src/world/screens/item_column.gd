class_name ItemColumn
extends VBoxContainer
# A titled, scrolling list of items, one button each, named in its rarity's colour with a price on the
# right if there is one. Two sit side by side in the stash and the vendor.

signal chosen(item: Item)
signal focused(item: Item)

const ROW_SIZE := 28

var items: Array[Item] = []
var buttons: Array[Button] = []
var _header: Label
var _scroll := ScrollContainer.new()
var _list := VBoxContainer.new()
var _empty := UiTheme.text("Empty", 26, UiTheme.DISABLED)

func _init(title: String) -> void:
	add_theme_constant_override("separation", 10)
	_header = UiTheme.heading(title, 34, UiTheme.PARCHMENT)
	add_child(_header)
	_scroll.custom_minimum_size = Vector2(540, 520)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	add_child(_scroll)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 2)
	_scroll.add_child(_list)
	_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_list.add_child(_empty)

# Rebuilds the list. price_of, if given, takes an Item and returns gold.
func show_items(shown: Array[Item], price_of := Callable()) -> void:
	items = shown.duplicate()
	# Not free(): this can run from inside a button's own pressed signal
	for button in buttons:
		_list.remove_child(button)
		button.queue_free()
	buttons.clear()
	_empty.visible = items.is_empty()
	for item in items:
		var button := Button.new()
		button.text = item.display_name if item.display_name != "" else String(item.base.display_name)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", ROW_SIZE)
		button.add_theme_color_override("font_color", item.colour())
		button.clip_text = true
		if price_of.is_valid():
			var price := UiTheme.text("%d g" % price_of.call(item), 26, UiTheme.GOLD)
			price.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT, Control.PRESET_MODE_KEEP_SIZE, 24)
			price.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			price.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(price)
		button.focus_entered.connect(func() -> void:
			Sound.play("focus")
			focused.emit(item))
		button.pressed.connect(func() -> void: chosen.emit(item))
		_list.add_child(button)
		buttons.append(button)
	for i in buttons.size():
		buttons[i].focus_neighbor_top = buttons[i].get_path_to(buttons[i - 1])
		buttons[i].focus_neighbor_bottom = buttons[i].get_path_to(buttons[(i + 1) % buttons.size()])

func focus_index(index: int) -> bool:
	if buttons.is_empty():
		return false
	buttons[clampi(index, 0, buttons.size() - 1)].grab_focus()
	return true

# Which row has focus, or -1
func focused_index() -> int:
	for i in buttons.size():
		if buttons[i].has_focus():
			return i
	return -1

# Left and right hop to the same row (or the nearest) in other, and nowhere if it's empty.
func link(other: ItemColumn, right: bool) -> void:
	for i in buttons.size():
		var target: Control = buttons[i] if other.buttons.is_empty() else other.buttons[mini(i, other.buttons.size() - 1)]
		var path := buttons[i].get_path_to(target)
		if right:
			buttons[i].focus_neighbor_right = path
			buttons[i].focus_neighbor_left = buttons[i].get_path_to(buttons[i])
		else:
			buttons[i].focus_neighbor_left = path
			buttons[i].focus_neighbor_right = buttons[i].get_path_to(buttons[i])
