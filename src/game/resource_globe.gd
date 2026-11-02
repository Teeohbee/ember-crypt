class_name ResourceGlobe
extends Control
# A D3 globe: a glass ball of liquid that drains as you lose health (or spend Fury / Arcane). What was
# just lost lingers as a pale band that drains after it, so a big hit reads at a glance. Below a
# quarter the bronze rim pulses, if asked to (health only). Redraws only when something changes.

const DIAMETER := 150.0
const TRAIL_DELAY := 0.35
const TRAIL_SPEED := 0.9   # fractions per second
const LOW := 0.25
const SEGMENTS := 40

var colour: Color
var pulse_when_low := false
var fraction := 0.0
var trail := 0.0
var readout := ""
var _trail_wait := 0.0
var _pulse := 0.0
var _points := PackedVector2Array()

func _init(liquid: Color, pulses := false) -> void:
	colour = liquid
	pulse_when_low = pulses
	custom_minimum_size = Vector2(DIAMETER, DIAMETER)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_values(current: float, maximum: float) -> void:
	var next := 0.0 if maximum <= 0.0 else clampf(current / maximum, 0.0, 1.0)
	var text := str(roundi(maxf(current, 0.0)))
	if is_equal_approx(next, fraction) and text == readout:
		return
	if next < fraction:
		_trail_wait = TRAIL_DELAY
	fraction = next
	trail = maxf(trail, fraction)
	readout = text
	queue_redraw()

# Drops the trail to match, for a first fill
func snap() -> void:
	trail = fraction
	queue_redraw()

func _process(delta: float) -> void:
	if trail > fraction:
		if _trail_wait > 0.0:
			_trail_wait -= delta
		else:
			trail = maxf(trail - TRAIL_SPEED * delta, fraction)
		queue_redraw()
	if pulse_when_low and fraction > 0.0 and fraction < LOW:
		_pulse = fmod(_pulse + delta * 2.2, 1.0)
		queue_redraw()
	elif _pulse != 0.0:
		_pulse = 0.0
		queue_redraw()

func _draw() -> void:
	var centre := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - 6.0
	draw_circle(centre, radius + 6.0, Color(UiTheme.VOID, 0.9))
	draw_circle(centre, radius, Color(colour.darkened(0.85), 0.95))
	if trail > fraction:
		_liquid(centre, radius, trail, Color(colour.lightened(0.45), 0.55))
	_liquid(centre, radius, fraction, colour)
	# Glass: a soft highlight up and to the left, and a darker lower rim
	draw_arc(centre, radius * 0.78, PI * 1.1, PI * 1.45, 16, Color(1, 1, 1, 0.18), radius * 0.12, true)
	draw_arc(centre, radius - 3.0, PI * 0.15, PI * 0.85, 24, Color(0, 0, 0, 0.35), 6.0, true)
	var rim := UiTheme.BRONZE
	if _pulse > 0.0:
		rim = UiTheme.BRONZE.lerp(Color(1.0, 0.2, 0.12), 0.5 + 0.5 * sin(_pulse * TAU))
	draw_arc(centre, radius + 2.0, 0.0, TAU, 64, rim, 4.0, true)
	draw_arc(centre, radius + 6.0, 0.0, TAU, 64, Color(UiTheme.GOLD, 0.35), 1.5, true)
	var font := UiTheme.body_font("Bold")
	var font_size := 26
	var width := font.get_string_size(readout, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var at := centre + Vector2(-width * 0.5, radius * 0.62)
	draw_string(font, at + Vector2(0, 2), readout, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.7))
	draw_string(font, at, readout, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UiTheme.PARCHMENT)

# The part of the circle below the liquid's surface
func _liquid(centre: Vector2, radius: float, level: float, liquid: Color) -> void:
	if level <= 0.0:
		return
	if level >= 0.999:
		draw_circle(centre, radius, liquid)
		return
	# Height of the surface below the centre, as a fraction of the radius (screen y points down)
	var surface := 1.0 - 2.0 * level
	var start := asin(surface)
	var finish := PI - start
	_points.resize(SEGMENTS + 1)
	for i in SEGMENTS + 1:
		var angle := lerpf(start, finish, float(i) / SEGMENTS)
		_points[i] = centre + Vector2(cos(angle), sin(angle)) * radius
	draw_colored_polygon(_points, liquid)
	# A bright meniscus along the top
	draw_line(_points[0], _points[SEGMENTS], Color(liquid.lightened(0.5), 0.8), 2.0, true)
