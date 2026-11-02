class_name OptionsMenu
extends PanelContainer
# The options screen, shared by the main menu and the pause menu. LB and RB switch tabs, as on D3's
# console menus; B closes. Every change is live and saved as it's made, so there's no Apply.

signal closed

# Each tab: its name and its rows as [label, setting]. Controls has no settings; it's the pad layout.
const TABS := [
	["Audio", [["Master volume", "master_volume"], ["Music", "music_volume"], ["Sound effects", "sound_volume"]]],
	["Display", [["Fullscreen", "fullscreen"], ["Vertical sync", "vsync"], ["Show frame rate", "show_fps"]]],
	["Gameplay", [["Screen shake", "screen_shake"], ["Controller rumble", "rumble"]]],
	["Controls", []],
]

const PAD_LAYOUT := [
	["ls", "Move"], ["rs", "Evade roll"], ["a", "Primary skill / pick up"], ["x", "Skill 2"],
	["y", "Skill 3"], ["b", "Skill 4"], ["rb", "Skill 5"], ["rt", "Skill 6"], ["lb", "Health potion"],
	["lt", "Lock on to target"], ["start", "Pause"], ["view", "Inventory"],
]

var tab := 0
var _tab_labels: Array[Label] = []
var _page := VBoxContainer.new()

func _ready() -> void:
	custom_minimum_size = Vector2(900, 700)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	add_child(column)
	column.add_child(UiTheme.heading("Options", 52))
	column.add_child(_tab_strip())
	column.add_child(UiTheme.divider(800))
	_page.add_theme_constant_override("separation", 4)
	_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_page)
	var prompts := PromptBar.new()
	prompts.show_prompts([["b", "Back"]])
	column.add_child(prompts)
	show_tab(0)

func open() -> void:
	show()
	Sound.play("open")
	show_tab(tab)

func show_tab(index: int) -> void:
	tab = wrapi(index, 0, TABS.size())
	for i in _tab_labels.size():
		_tab_labels[i].add_theme_color_override("font_color", UiTheme.GOLD if i == tab else UiTheme.FADED)
	for child in _page.get_children():
		_page.remove_child(child)
		child.queue_free()
	var rows: Array = TABS[tab][1]
	if rows.is_empty():
		_show_pad_layout()
		return
	var buttons: Array[OptionRow] = []
	for row: Array in rows:
		var option := OptionRow.new(row[0], row[1])
		_page.add_child(option)
		buttons.append(option)
	for i in buttons.size():
		buttons[i].focus_neighbor_top = buttons[i].get_path_to(buttons[i - 1])
		buttons[i].focus_neighbor_bottom = buttons[i].get_path_to(buttons[(i + 1) % buttons.size()])
	_focus_first_row.call_deferred()

# Deferred, and looks the row up when it runs: switching tabs twice in a frame frees the rows the first
# switch made
func _focus_first_row() -> void:
	if not is_visible_in_tree():
		return
	for child in _page.get_children():
		if child is OptionRow and not child.is_queued_for_deletion():
			child.grab_focus()
			return

func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed("tab_previous") or event.is_action_pressed("tab_next"):
		get_viewport().set_input_as_handled()
		show_tab(tab + (-1 if event.is_action_pressed("tab_previous") else 1))
		Sound.play("tick")
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Sound.play("back")
		hide()
		closed.emit()

func _tab_strip() -> Control:
	var strip := HBoxContainer.new()
	strip.alignment = BoxContainer.ALIGNMENT_CENTER
	strip.add_theme_constant_override("separation", 40)
	strip.add_child(ButtonGlyph.new("lb", 34))
	for entry: Array in TABS:
		var label := UiTheme.heading(entry[0], 30, UiTheme.FADED)
		strip.add_child(label)
		_tab_labels.append(label)
	strip.add_child(ButtonGlyph.new("rb", 34))
	return strip

func _show_pad_layout() -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 70)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for half in [PAD_LAYOUT.slice(0, 6), PAD_LAYOUT.slice(6)]:
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 12)
		for entry: Array in half:
			var line := HBoxContainer.new()
			line.add_theme_constant_override("separation", 16)
			line.add_child(ButtonGlyph.new(entry[0], 40))
			line.add_child(UiTheme.text(entry[1], 28))
			column.add_child(line)
		grid.add_child(column)
	_page.add_child(grid)
