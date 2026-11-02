class_name CharacterList
extends Control
# The saved characters, most recently played first, down the left of the front end. Each row says who
# they are and how far they've got; focusing one lights their class's hero in the crypt behind. A plays,
# X deletes (after asking, defaulting to keep), B steps back to the menu.

signal chosen(id: String)
signal focused(record: Dictionary)
signal back

var rows: Array[Button] = []
var confirm := ConfirmBox.new()

var _column := VBoxContainer.new()
var _list := VBoxContainer.new()
var _prompts: PromptBar
var _asking := 0

func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_column)
	_column.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT, Control.PRESET_MODE_KEEP_SIZE, 140)
	_column.grow_vertical = Control.GROW_DIRECTION_BOTH
	_column.add_theme_constant_override("separation", 14)
	_column.custom_minimum_size.x = 640
	_column.add_child(UiTheme.heading("Characters", 64, UiTheme.GOLD))
	_column.add_child(UiTheme.divider(560))
	_list.add_theme_constant_override("separation", 4)
	_column.add_child(_list)
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	centre.add_child(confirm)
	confirm.hide()
	# Kept: back to the row that was asked about. Deleted: open() rebuilds the rows.
	confirm.answered.connect(func(yes: bool) -> void:
		if not yes:
			_focus_row(_asking))
	_prompts = PromptBar.in_corner(self)
	_prompts.show_prompts([["a", "Play"], ["x", "Delete"], ["b", "Back"]])

# Rebuilds the rows from SaveGame and focuses the first (the last played)
func open() -> void:
	for row in rows:
		_list.remove_child(row)
		row.queue_free()
	rows.clear()
	for record in SaveGame.sorted():
		rows.append(_row(record))
	for i in rows.size():
		rows[i].focus_neighbor_top = rows[i].get_path_to(rows[i - 1])
		rows[i].focus_neighbor_bottom = rows[i].get_path_to(rows[(i + 1) % rows.size()])
		rows[i].focus_neighbor_left = rows[i].get_path_to(rows[i])
		rows[i].focus_neighbor_right = rows[i].get_path_to(rows[i])
	_focus_row(0)

func _row(record: Dictionary) -> Button:
	var row := Button.new()
	row.name = "Character%d" % rows.size()
	row.text = record.name
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.custom_minimum_size = Vector2(640, 66)
	row.set_meta("record", record)
	var detail := UiTheme.text("Level %d %s" % [record.level, SaveGame.class_of(record).display_name], 26, UiTheme.FADED)
	detail.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT, Control.PRESET_MODE_KEEP_SIZE, 28)
	detail.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	detail.grow_vertical = Control.GROW_DIRECTION_BOTH
	row.add_child(detail)
	row.focus_entered.connect(func() -> void:
		Sound.play("focus")
		focused.emit(record))
	row.pressed.connect(func() -> void:
		Sound.play("confirm")
		chosen.emit(record.id))
	_list.add_child(row)
	return row

func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or confirm.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Sound.play("back")
		back.emit()
	elif event.is_action_pressed("menu_delete"):
		var row := get_viewport().gui_get_focus_owner() as Button
		if row in rows:
			get_viewport().set_input_as_handled()
			_asking = rows.find(row)
			_ask_delete(row.get_meta("record"))

func _ask_delete(record: Dictionary) -> void:
	Sound.play("open")
	confirm.ask("Delete %s for good?" % record.name, func() -> void:
		SaveGame.delete(record.id)
		Sound.play("denied")
		if SaveGame.characters.is_empty():
			back.emit()
		else:
			open(), "Delete", "Keep")

func _focus_row(index: int) -> void:
	if rows.is_empty() or not is_visible_in_tree():
		return
	rows[clampi(index, 0, rows.size() - 1)].grab_focus()
