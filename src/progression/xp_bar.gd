class_name XpBar
extends Control
# The XP bar: a thin gold line along the bottom of the screen with the hero's level at its left end,
# notched in tenths the way Diablo's is. It fills smoothly as XP comes in, sweeps to the end and empties
# on a level-up, and at the level cap it stays full.

const WIDTH := 880.0
const HEIGHT := 10.0
const FROM_BOTTOM := 18.0
const NOTCHES := 10

var slot: PlayerSlot
var hero: Hero
var level_label := UiTheme.heading("1", 26, UiTheme.GOLD)
# What's drawn, 0-1; eases towards the hero's real fraction
var shown := 0.0
var _tween: Tween

func _init(player_slot: PlayerSlot) -> void:
	slot = player_slot
	name = "XpBar"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(WIDTH, HEIGHT)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_KEEP_SIZE, int(FROM_BOTTOM))
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	level_label.custom_minimum_size = Vector2(60, 0)
	level_label.position = Vector2(-72, -14)
	add_child(level_label)

func _ready() -> void:
	hero = slot.hero
	if hero == null:
		hide()
		return
	hero.progress.xp_changed.connect(_on_xp_changed)
	hero.progress.levelled_up.connect(_on_levelled_up)
	shown = hero.progress.fraction()
	level_label.text = str(hero.level)

func _on_xp_changed(_xp: int, _needed: int) -> void:
	level_label.text = str(hero.level)
	_ease_to(hero.progress.fraction(), 0.4)

# Sweep to the end, empty, then fill to where the new level's XP stands
func _on_levelled_up(_level: int) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_shown, shown, 1.0, 0.25)
	_tween.tween_interval(0.2)
	_tween.tween_callback(_set_shown.bind(0.0))
	_tween.tween_method(_set_shown, 0.0, hero.progress.fraction(), 0.4)

func _ease_to(fraction: float, seconds: float) -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_shown, shown, fraction, seconds)

func _set_shown(fraction: float) -> void:
	shown = clampf(fraction, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	var bar := Rect2(Vector2.ZERO, size)
	draw_rect(bar.grow(2.0), Color(UiTheme.VOID, 0.85))
	draw_rect(bar, Color(UiTheme.SOOT, 0.9))
	if shown > 0.0:
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * shown, bar.size.y)), Color(UiTheme.GOLD, 0.9))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * shown, 2.0)), Color(1.0, 0.95, 0.8, 0.6))
	for i in range(1, NOTCHES):
		var x := bar.size.x * i / NOTCHES
		draw_line(Vector2(x, 0), Vector2(x, bar.size.y), Color(UiTheme.VOID, 0.8), 2.0)
	draw_rect(bar.grow(2.0), UiTheme.BRONZE, false, 1.5)
