class_name ItemIcon
extends Control
# An item drawn as a glyph in its rarity colour: the kit has no icon art, so each kind of item (axe,
# shield, boots...) is a few strokes. paint() is static so slot buttons can draw one too.

var kind := ""
var colour := Color.WHITE

func _init(item_kind := "", tint := Color.WHITE, side := 64.0) -> void:
	kind = item_kind
	colour = tint
	custom_minimum_size = Vector2(side, side)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	paint(self, kind, Rect2(Vector2.ZERO, size), colour)

# Draws kind inside rect. Shapes are in a unit square, scaled to fit.
static func paint(canvas: CanvasItem, item_kind: String, rect: Rect2, tint: Color) -> void:
	var s := minf(rect.size.x, rect.size.y)
	var origin := rect.position + (rect.size - Vector2(s, s)) * 0.5
	var width := maxf(2.0, s * 0.06)
	var fill := Color(tint, 0.22)
	var at := func(x: float, y: float) -> Vector2: return origin + Vector2(x, y) * s
	var shape := func(points: Array) -> void:
		var polygon := PackedVector2Array()
		for p: Vector2 in points:
			polygon.append(at.call(p.x, p.y))
		canvas.draw_colored_polygon(polygon, fill)
		polygon.append(polygon[0])
		canvas.draw_polyline(polygon, tint, width, true)
	var line := func(a: Vector2, b: Vector2, thick := 1.0) -> void:
		canvas.draw_line(at.call(a.x, a.y), at.call(b.x, b.y), tint, width * thick, true)
	match item_kind:
		"axe":
			line.call(Vector2(0.25, 0.88), Vector2(0.62, 0.14))
			shape.call([Vector2(0.52, 0.14), Vector2(0.84, 0.16), Vector2(0.9, 0.46), Vector2(0.62, 0.42)])
		"sword", "dagger":
			var reach := 0.18 if item_kind == "sword" else 0.42
			line.call(Vector2(0.36, 0.64), Vector2(0.82 - reach * 0.5, reach), 1.6)
			line.call(Vector2(0.22, 0.56), Vector2(0.46, 0.8))
			line.call(Vector2(0.34, 0.68), Vector2(0.2, 0.82))
			canvas.draw_circle(at.call(0.18, 0.85), s * 0.05, tint)
		"staff":
			line.call(Vector2(0.3, 0.92), Vector2(0.6, 0.24), 1.2)
			canvas.draw_circle(at.call(0.64, 0.16), s * 0.1, fill)
			canvas.draw_arc(at.call(0.64, 0.16), s * 0.1, 0.0, TAU, 20, tint, width, true)
		"wand":
			line.call(Vector2(0.3, 0.82), Vector2(0.64, 0.3), 1.2)
			shape.call([Vector2(0.7, 0.12), Vector2(0.76, 0.24), Vector2(0.7, 0.36), Vector2(0.64, 0.24)])
		"shield":
			shape.call([Vector2(0.2, 0.18), Vector2(0.8, 0.18), Vector2(0.8, 0.5), Vector2(0.5, 0.88), Vector2(0.2, 0.5)])
			line.call(Vector2(0.5, 0.2), Vector2(0.5, 0.84), 0.6)
		"tome":
			shape.call([Vector2(0.26, 0.16), Vector2(0.76, 0.16), Vector2(0.76, 0.84), Vector2(0.26, 0.84)])
			line.call(Vector2(0.34, 0.16), Vector2(0.34, 0.84), 0.7)
			line.call(Vector2(0.46, 0.4), Vector2(0.66, 0.4), 0.6)
		"helm":
			shape.call([Vector2(0.2, 0.72), Vector2(0.22, 0.4), Vector2(0.36, 0.22), Vector2(0.5, 0.18),
				Vector2(0.64, 0.22), Vector2(0.78, 0.4), Vector2(0.8, 0.72)])
			line.call(Vector2(0.5, 0.4), Vector2(0.5, 0.82), 0.9)
		"chest":
			shape.call([Vector2(0.24, 0.2), Vector2(0.4, 0.14), Vector2(0.5, 0.24), Vector2(0.6, 0.14), Vector2(0.76, 0.2),
				Vector2(0.84, 0.46), Vector2(0.7, 0.5), Vector2(0.7, 0.86), Vector2(0.3, 0.86), Vector2(0.3, 0.5), Vector2(0.16, 0.46)])
		"gloves":
			shape.call([Vector2(0.3, 0.88), Vector2(0.3, 0.36), Vector2(0.7, 0.36), Vector2(0.7, 0.88)])
			for x in [0.36, 0.5, 0.64]:
				line.call(Vector2(x, 0.36), Vector2(x, 0.14))
			line.call(Vector2(0.3, 0.56), Vector2(0.16, 0.38))
		"boots":
			shape.call([Vector2(0.34, 0.14), Vector2(0.6, 0.14), Vector2(0.6, 0.58), Vector2(0.86, 0.68),
				Vector2(0.86, 0.86), Vector2(0.34, 0.86)])
		"ring":
			canvas.draw_arc(at.call(0.5, 0.6), s * 0.22, 0.0, TAU, 28, tint, width * 1.3, true)
			shape.call([Vector2(0.5, 0.18), Vector2(0.6, 0.3), Vector2(0.5, 0.42), Vector2(0.4, 0.3)])
		"amulet":
			line.call(Vector2(0.24, 0.14), Vector2(0.5, 0.56), 0.7)
			line.call(Vector2(0.76, 0.14), Vector2(0.5, 0.56), 0.7)
			canvas.draw_circle(at.call(0.5, 0.68), s * 0.13, fill)
			canvas.draw_arc(at.call(0.5, 0.68), s * 0.13, 0.0, TAU, 24, tint, width, true)
		_:
			shape.call([Vector2(0.5, 0.15), Vector2(0.8, 0.5), Vector2(0.5, 0.85), Vector2(0.2, 0.5)])
