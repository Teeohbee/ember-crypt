class_name ButtonGlyph
extends Control
# A pad button, drawn: face buttons as rings in their Xbox / Steam Deck colours (muted to sit with
# the parchment), shoulders and triggers as labelled pills, Start and View as rings with their icons,
# and the D-pad and sticks as outlines.

const FACES := {"a": Color("6fae5a"), "b": Color("c4523f"), "x": Color("4f86c6"), "y": Color("d8b44a")}
const PILLS := ["lb", "rb", "lt", "rt"]
const OTHERS := ["start", "view", "dpad", "ls", "rs"]

var button: String

static func knows(button_name: String) -> bool:
	return button_name in FACES or button_name in PILLS or button_name in OTHERS

func _init(button_name := "a", height := 36.0) -> void:
	if not knows(button_name):
		push_error("No glyph for pad button '%s'" % button_name)
	button = button_name
	var width := height * 1.5 if button in PILLS else height
	custom_minimum_size = Vector2(width, height)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var s := size.y
	var centre := size * 0.5
	var line := maxf(2.0, s * 0.07)
	var radius := s * 0.5 - line
	var ink := UiTheme.PARCHMENT
	if button in FACES:
		draw_circle(centre, radius, Color(UiTheme.VOID, 0.85))
		draw_arc(centre, radius, 0.0, TAU, 40, FACES[button], line, true)
		_letter(button.to_upper(), centre, s * 0.56, FACES[button])
	elif button in PILLS:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(UiTheme.VOID, 0.85)
		box.border_color = ink
		box.set_border_width_all(int(line))
		box.set_corner_radius_all(int(s * 0.3))
		box.anti_aliasing = true
		draw_style_box(box, Rect2(Vector2.ZERO, size))
		_letter(button.to_upper(), centre, s * 0.48, ink)
	elif button in ["start", "view"]:
		draw_circle(centre, radius, Color(UiTheme.VOID, 0.85))
		draw_arc(centre, radius, 0.0, TAU, 40, ink, line, true)
		if button == "start":
			for row in [-1, 0, 1]:
				var y: float = centre.y + row * s * 0.13
				draw_line(Vector2(centre.x - s * 0.18, y), Vector2(centre.x + s * 0.18, y), ink, line * 0.9, true)
		else:
			var window := Vector2(s * 0.26, s * 0.2)
			draw_rect(Rect2(centre + Vector2(-0.19, -0.16) * s, window), ink, false, line * 0.8)
			draw_rect(Rect2(centre + Vector2(-0.07, -0.04) * s, window), ink)
	elif button == "dpad":
		var arm := s * 0.17
		var reach := radius
		var points := PackedVector2Array()
		for corner in [Vector2(-arm, -reach), Vector2(arm, -reach), Vector2(arm, -arm), Vector2(reach, -arm),
				Vector2(reach, arm), Vector2(arm, arm), Vector2(arm, reach), Vector2(-arm, reach), Vector2(-arm, arm),
				Vector2(-reach, arm), Vector2(-reach, -arm), Vector2(-arm, -arm), Vector2(-arm, -reach)]:
			points.append(centre + corner)
		draw_polyline(points, ink, line, true)
	else:
		# Sticks: a ring with a dot, and the letter of which side
		draw_arc(centre, radius, 0.0, TAU, 40, ink, line, true)
		draw_circle(centre, radius * 0.55, Color(ink, 0.25))
		_letter(button.substr(0, 1).to_upper(), centre, s * 0.42, ink)

func _letter(text: String, centre: Vector2, font_size: float, colour: Color) -> void:
	var font := UiTheme.body_font("Bold")
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(font_size)).x
	draw_string(font, centre + Vector2(-width * 0.5, font_size * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(font_size), colour)
