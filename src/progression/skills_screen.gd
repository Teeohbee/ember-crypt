class_name SkillsScreen
extends CanvasLayer
# The skills screen, on the D-pad (left): the hero's six skill slots, each with its rune, and below the
# focused one what it does, its runes and the levels they come at. Up and down pick a skill, left and
# right change its rune, B (or the D-pad again) closes. The game pauses underneath, and the hero is
# saved on the way out.

signal closed

var slot: PlayerSlot
var is_open := false
var rows: Array[SkillRow] = []

var _backdrop := ColorRect.new()
var _panel := PanelContainer.new()
var _rows := VBoxContainer.new()
var _detail_title := UiTheme.heading("", 34, UiTheme.GOLD)
var _detail := UiTheme.text("", 26)
var _runes := VBoxContainer.new()
var _level := UiTheme.text("", 28, UiTheme.FADED)

func _init(player_slot: PlayerSlot) -> void:
	slot = player_slot
	name = "SkillsScreen%d" % player_slot.index
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	_backdrop.color = Color(UiTheme.VOID, 0.7)
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_backdrop)
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	centre.add_child(_panel)
	_panel.custom_minimum_size.x = 1040
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_panel.add_child(column)
	column.add_child(UiTheme.heading("Skills", 52))
	_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_level)
	column.add_child(UiTheme.divider(900))
	_rows.add_theme_constant_override("separation", 2)
	column.add_child(_rows)
	column.add_child(UiTheme.divider(900))
	column.add_child(_detail_title)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size = Vector2(940, 70)
	_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_detail)
	_runes.add_theme_constant_override("separation", 2)
	_runes.custom_minimum_size.y = 120
	column.add_child(_runes)
	var prompts := PromptBar.new()
	prompts.show_prompts([["dpad", "Change rune"], ["b", "Back"]])
	column.add_child(prompts)
	hide()

# Closing is caught before anything else sees it: the skills button is D-pad left on the pad, which the
# focused row would take as "previous rune", and Start would open the pause menu on top
func _input(event: InputEvent) -> void:
	if is_open and (event.is_action_pressed("skills_menu") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close()

# Opens only from the game itself, not over the pause menu or another screen
func _unhandled_input(event: InputEvent) -> void:
	if is_open or SceneManager.is_changing or slot.hero == null or get_tree().paused:
		return
	if event.is_action_pressed("skills_menu"):
		get_viewport().set_input_as_handled()
		open()

func open() -> void:
	is_open = true
	get_tree().paused = true
	Sound.play("open")
	_build_rows()
	show()
	for row in rows:
		if row.focus_mode != Control.FOCUS_NONE:
			row.grab_focus()
			break

func close() -> void:
	is_open = false
	get_viewport().gui_release_focus()
	hide()
	get_tree().paused = false
	Sound.play("back")
	SaveGame.store(slot.hero)
	closed.emit()

func _build_rows() -> void:
	var hero := slot.hero
	_level.text = "Level %d %s" % [hero.level, hero.hero_class.display_name]
	for row in rows:
		_rows.remove_child(row)
		row.queue_free()
	rows.clear()
	for i in SkillBar.SLOTS:
		var skill: SkillDef = hero.hero_class.skills[i] if i < hero.hero_class.skills.size() else null
		var row := SkillRow.new(i, skill, hero.progress)
		_rows.add_child(row)
		rows.append(row)
		row.focus_entered.connect(_describe.bind(row))
		row.rune_changed.connect(_describe.bind(row))
	var focusable := rows.filter(func(row: SkillRow) -> bool: return row.focus_mode != Control.FOCUS_NONE)
	for i in focusable.size():
		var row: SkillRow = focusable[i]
		row.focus_neighbor_top = row.get_path_to(focusable[i - 1])
		row.focus_neighbor_bottom = row.get_path_to(focusable[(i + 1) % focusable.size()])
		row.focus_neighbor_left = row.get_path_to(row)
		row.focus_neighbor_right = row.get_path_to(row)
	if focusable.is_empty():
		_detail_title.text = ""
		_detail.text = "No skills yet."
		_clear_runes()

func _describe(row: SkillRow) -> void:
	var skill := row.skill
	_detail_title.text = skill.display_name
	_detail.text = skill.description if row.unlocked() else "Unlocks at level %d." % skill.unlock_level
	_clear_runes()
	var current := row.progress.rune_for(skill.id)
	for rune in RuneLibrary.runes_for(skill.id):
		var line := UiTheme.text("", 24)
		var reached := rune.unlock_level <= row.progress.hero.level
		if reached:
			line.text = "%s%s - %s" % ["◆ " if rune == current else "", rune.display_name, rune.description]
		else:
			line.text = "%s - level %d" % [rune.display_name, rune.unlock_level]
		line.add_theme_color_override("font_color", UiTheme.GOLD if rune == current else (UiTheme.PARCHMENT if reached else UiTheme.DISABLED))
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.custom_minimum_size.x = 940
		_runes.add_child(line)

func _clear_runes() -> void:
	for child in _runes.get_children():
		_runes.remove_child(child)
		child.queue_free()
