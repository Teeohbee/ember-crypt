class_name SkillSlot
extends Control
# One socket on the skill bar: the skill's icon (its texture if it has one, otherwise its initials on
# a disc in the colour of its damage), a dark sweep that unwinds clockwise as the cooldown runs out
# with the seconds left on top, a red wash when there isn't enough power, a gold flare when it comes
# ready, and the pad button that fires it. An empty socket is just a dim ring; one holding a skill the
# hero hasn't reached yet shows a padlock and the level it opens at. The potion uses one too.

const DIAMETER := 84.0
const FLASH_SECONDS := 0.4
const KIND_COLOURS := {
	DamageEvent.Kind.PHYSICAL: Color("8a6a45"),
	DamageEvent.Kind.FIRE: Color("c4532a"),
	DamageEvent.Kind.COLD: Color("4f8fc4"),
	DamageEvent.Kind.LIGHTNING: Color("c9b04a"),
	DamageEvent.Kind.ARCANE: Color("8452c9"),
	DamageEvent.Kind.POISON: Color("5f9a45"),
}
const SWEEP_SEGMENTS := 32

var button: String
var empty := true
var initials := ""
var icon: Texture2D
var tint := Color.WHITE
var cooldown := 0.0
var countdown := ""
var affordable := true
var ready_flash := 0.0
var used_flash := 0.0
var denied_flash := 0.0
# Draws a flask instead of initials (the potion)
var flask := false
# The level a skill waiting in this socket unlocks at; 0 when there's none waiting
var locked_level := 0
var _sweep := PackedVector2Array()
static var _font: Font

func _init(button_name: String) -> void:
	button = button_name
	custom_minimum_size = Vector2(DIAMETER, DIAMETER + 14.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glyph := ButtonGlyph.new(button_name, 30.0)
	glyph.name = "Glyph"
	add_child(glyph)

func _ready() -> void:
	resized.connect(_place_glyph)
	_place_glyph()

func _place_glyph() -> void:
	var glyph: Control = $Glyph
	glyph.size = glyph.custom_minimum_size
	glyph.position = Vector2((size.x - glyph.size.x) * 0.5, DIAMETER - glyph.size.y * 0.45)

func show_skill(skill: SkillDef, cooldown_fraction: float, cooldown_left: float, can_afford: bool, locked_at := 0) -> void:
	var was_cooling := cooldown > 0.0
	var next_initials := ""
	if skill:
		for word in skill.display_name.split(" ", false):
			if next_initials.length() < 2:
				next_initials += word.substr(0, 1).to_upper()
		icon = skill.icon
		tint = KIND_COLOURS.get(skill.damage_kind, KIND_COLOURS[DamageEvent.Kind.PHYSICAL])
	var next_countdown := str(ceili(cooldown_left)) if cooldown_left > 1.0 else ""
	var changed := empty != (skill == null) or initials != next_initials or affordable != can_afford \
		or countdown != next_countdown or not is_equal_approx(cooldown, cooldown_fraction) or locked_level != locked_at
	empty = skill == null
	locked_level = locked_at
	initials = next_initials
	affordable = can_afford
	countdown = next_countdown
	cooldown = cooldown_fraction
	if was_cooling and cooldown <= 0.0 and not empty:
		ready_flash = FLASH_SECONDS
	if changed:
		queue_redraw()

func flash_used() -> void:
	used_flash = FLASH_SECONDS * 0.5
	queue_redraw()

func flash_denied() -> void:
	denied_flash = FLASH_SECONDS
	queue_redraw()

func _process(delta: float) -> void:
	if ready_flash > 0.0 or used_flash > 0.0 or denied_flash > 0.0:
		ready_flash = maxf(ready_flash - delta, 0.0)
		used_flash = maxf(used_flash - delta, 0.0)
		denied_flash = maxf(denied_flash - delta, 0.0)
		queue_redraw()

func _draw() -> void:
	var radius := DIAMETER * 0.5 - 4.0
	# Shake sideways when denied
	var centre := Vector2(size.x * 0.5 + sin(denied_flash * 60.0) * denied_flash * 14.0, DIAMETER * 0.5)
	draw_circle(centre, radius + 4.0, Color(UiTheme.VOID, 0.88))
	if empty:
		draw_arc(centre, radius, 0.0, TAU, 48, Color(UiTheme.BRONZE, 0.45), 2.0, true)
		if locked_level > 0:
			_draw_padlock(centre + Vector2(0, -radius * 0.18), radius * 0.36, Color(UiTheme.BRONZE, 0.75))
			_letters("Lv %d" % locked_level, centre + Vector2(0, radius * 0.42), 18, Color(UiTheme.PARCHMENT, 0.7))
		return
	if icon:
		var box := Rect2(centre - Vector2(radius, radius) * 0.86, Vector2(radius, radius) * 1.72)
		draw_texture_rect(icon, box, false)
	else:
		draw_circle(centre, radius, tint.darkened(0.55))
		draw_circle(centre + Vector2(0, -radius * 0.12), radius * 0.78, tint.darkened(0.2))
		if flask:
			_draw_flask(centre, radius)
		else:
			_letters(initials, centre, 34, UiTheme.PARCHMENT)
	if not affordable:
		draw_circle(centre, radius, Color(0.35, 0.02, 0.02, 0.6))
	if cooldown > 0.0:
		_draw_sweep(centre, radius, cooldown)
		if countdown != "":
			_letters(countdown, centre, 36, UiTheme.PARCHMENT)
	var rim := UiTheme.BRONZE
	if denied_flash > 0.0:
		rim = rim.lerp(Color(1.0, 0.15, 0.1), denied_flash / FLASH_SECONDS)
	draw_arc(centre, radius + 1.0, 0.0, TAU, 48, rim, 3.0, true)
	if ready_flash > 0.0:
		var t := ready_flash / FLASH_SECONDS
		draw_arc(centre, radius + 2.0 + (1.0 - t) * 10.0, 0.0, TAU, 48, Color(UiTheme.GOLD, t), 4.0, true)
	if used_flash > 0.0:
		draw_circle(centre, radius, Color(1, 0.9, 0.7, used_flash / (FLASH_SECONDS * 0.5) * 0.35))

# A dark pie over the part of the cooldown still to run, starting at twelve o'clock
func _draw_sweep(centre: Vector2, radius: float, left: float) -> void:
	var steps := maxi(int(SWEEP_SEGMENTS * left), 2)
	_sweep.resize(steps + 2)
	_sweep[0] = centre
	var start := -PI * 0.5
	var span := TAU * left
	for i in steps + 1:
		var angle := start - span + span * float(i) / steps
		_sweep[i + 1] = centre + Vector2(cos(angle), sin(angle)) * radius
	draw_colored_polygon(_sweep, Color(0, 0, 0, 0.68))

func _draw_flask(centre: Vector2, radius: float) -> void:
	var body := centre + Vector2(0, radius * 0.18)
	draw_rect(Rect2(centre + Vector2(-radius * 0.13, -radius * 0.62), Vector2(radius * 0.26, radius * 0.4)), UiTheme.PARCHMENT.darkened(0.2))
	draw_rect(Rect2(centre + Vector2(-radius * 0.19, -radius * 0.7), Vector2(radius * 0.38, radius * 0.1)), UiTheme.BRONZE)
	draw_circle(body, radius * 0.44, UiTheme.PARCHMENT.darkened(0.2))
	draw_circle(body, radius * 0.37, Color(0.75, 0.08, 0.06))
	draw_circle(body + Vector2(-radius * 0.13, -radius * 0.13), radius * 0.08, Color(1, 1, 1, 0.5))

func _letters(text: String, centre: Vector2, font_size: int, colour: Color) -> void:
	if _font == null:
		_font = UiTheme.heading_font(700)
	var font := _font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var at := centre + Vector2(-width * 0.5, font_size * 0.36)
	draw_string(font, at + Vector2(0, 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.75))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)

# A padlock about `size` across: a shackle arc over a squared body
func _draw_padlock(centre: Vector2, size: float, colour: Color) -> void:
	var body := Rect2(centre + Vector2(-size * 0.5, -size * 0.05), Vector2(size, size * 0.75))
	draw_arc(centre + Vector2(0, -size * 0.05), size * 0.32, PI, TAU, 16, colour, maxf(size * 0.14, 2.0), true)
	draw_rect(body, colour)
	draw_circle(centre + Vector2(0, size * 0.3), size * 0.1, Color(UiTheme.VOID, 0.9))
