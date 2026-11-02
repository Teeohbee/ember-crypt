class_name SkillRow
extends Button
# One skill on the skills screen: its button, its name and the rune set in it. Left and right step
# through the runes the hero has unlocked for it (and "No rune"), setting each as it lands, so there's
# nothing to confirm. A locked skill says when it unlocks and won't take a rune.

signal rune_changed

const GLYPHS := ["a", "x", "y", "b", "rb", "rt"]

var index := 0
var skill: SkillDef
var progress: HeroProgress
var name_label := UiTheme.text("", 32)
var rune_label := UiTheme.text("", 28, UiTheme.FADED)

func _init(slot_index: int, slot_skill: SkillDef, hero_progress: HeroProgress) -> void:
	index = slot_index
	skill = slot_skill
	progress = hero_progress
	name = "Skill%d" % slot_index
	custom_minimum_size = Vector2(940, 64)
	focus_mode = Control.FOCUS_ALL if skill else Control.FOCUS_NONE
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 22
	row.offset_right = -22
	row.add_theme_constant_override("separation", 18)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	row.add_child(ButtonGlyph.new(GLYPHS[slot_index], 40))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_override("font", UiTheme.heading_font(600))
	row.add_child(name_label)
	rune_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(rune_label)
	focus_entered.connect(func() -> void: Sound.play("focus"))
	refresh()

func unlocked() -> bool:
	return skill != null and skill.unlock_level <= progress.hero.level

# "No rune" (empty id) then the skill's runes the hero's level has reached
func choices() -> Array[StringName]:
	var found: Array[StringName] = [&""]
	if skill:
		for rune in RuneLibrary.runes_for(skill.id):
			if rune.unlock_level <= progress.hero.level:
				found.append(rune.id)
	return found

# Steps to the next (or previous) unlocked rune and sets it. False if there was nowhere to go.
func cycle(step: int) -> bool:
	var options := choices()
	if not unlocked() or options.size() < 2:
		Sound.play("denied", 1.0, -6.0)
		return false
	var current := progress.runes.get(skill.id, &"") as StringName
	var next := options[wrapi(options.find(current) + step, 0, options.size())]
	progress.set_rune(skill.id, next)
	Sound.play("rune" if next != &"" else "tick")
	refresh()
	rune_changed.emit()
	return true

func refresh() -> void:
	if skill == null:
		name_label.text = "Empty"
		name_label.add_theme_color_override("font_color", UiTheme.DISABLED)
		rune_label.text = ""
		return
	name_label.text = skill.display_name
	var open := unlocked()
	name_label.add_theme_color_override("font_color", UiTheme.PARCHMENT if open else UiTheme.DISABLED)
	if not open:
		rune_label.text = "Unlocks at level %d" % skill.unlock_level
	elif RuneLibrary.runes_for(skill.id).is_empty():
		rune_label.text = ""
	else:
		var rune := progress.rune_for(skill.id)
		rune_label.text = "‹  %s  ›" % (rune.display_name if rune else "No rune")
	rune_label.add_theme_color_override("font_color", UiTheme.GOLD if progress.rune_for(skill.id) else UiTheme.FADED)

func _gui_input(event: InputEvent) -> void:
	for step in [-1, 1]:
		if event.is_action_pressed("ui_left" if step < 0 else "ui_right", true):
			accept_event()
			cycle(step)
