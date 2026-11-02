class_name LevelBanner
extends Control
# Rises in when the hero levels up: "Level 5" in gold, what it unlocked underneath, and if there's
# anything new to choose, a reminder of where the skills screen is. Holds for a few seconds, then fades.

const HOLD_SECONDS := 3.5

var slot: PlayerSlot
var title := UiTheme.heading("", 76, UiTheme.GOLD)
var unlocks := VBoxContainer.new()
var hint := PromptBar.new()
var _column := VBoxContainer.new()
var _tween: Tween

func _init(player_slot: PlayerSlot) -> void:
	slot = player_slot
	name = "LevelBanner"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_column)
	_column.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_KEEP_SIZE, 230)
	_column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_column.add_theme_constant_override("separation", 8)
	title.add_theme_color_override("font_shadow_color", Color(UiTheme.EMBER, 0.6))
	title.add_theme_constant_override("shadow_outline_size", 22)
	title.add_theme_constant_override("shadow_offset_y", 0)
	_column.add_child(title)
	_column.add_child(UiTheme.divider(420))
	_column.add_child(unlocks)
	hint.alignment = BoxContainer.ALIGNMENT_CENTER
	_column.add_child(hint)
	hide()

func _ready() -> void:
	if slot.hero:
		slot.hero.progress.levelled_up.connect(announce)

func announce(level: int) -> void:
	title.text = "Level %d" % level
	for child in unlocks.get_children():
		child.queue_free()
	var found := slot.hero.progress.unlocks_between(slot.hero.progress.level_before, level)
	for line in found:
		var label := UiTheme.text(line, 30, UiTheme.PARCHMENT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		unlocks.add_child(label)
	hint.show_prompts([["dpad", "Skills"]] if not found.is_empty() else [])
	if _tween:
		_tween.kill()
	show()
	_column.modulate.a = 0.0
	_column.scale = Vector2.ONE * 1.15
	_column.pivot_offset = Vector2(_column.size.x * 0.5, 0)
	_tween = create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_column, "modulate:a", 1.0, 0.3)
	_tween.tween_property(_column, "scale", Vector2.ONE, 0.45)
	_tween.chain().tween_interval(HOLD_SECONDS)
	_tween.chain().tween_property(_column, "modulate:a", 0.0, 1.0)
	_tween.chain().tween_callback(hide)
