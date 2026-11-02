class_name ClassPanel
extends Control
# Class select's card: name, epithet, a few lines on how they play, their resource, and pip ratings.
# It sits on the half of the screen the chosen hero isn't standing in, sliding across when the
# choice changes sides.

const WIDTH := 640.0
const MARGIN := 140.0
const PIPS := 5

var _card := PanelContainer.new()
var _name := UiTheme.heading("", 72, UiTheme.GOLD)
var _epithet := UiTheme.heading("", 26, UiTheme.FADED)
var _blurb := UiTheme.text("", 28)
var _resource := UiTheme.text("", 28)
var _ratings := GridContainer.new()
var _slide: Tween

func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card)
	_card.custom_minimum_size.x = WIDTH
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	_card.add_child(column)
	column.add_child(_name)
	column.add_child(_epithet)
	column.add_child(UiTheme.divider(WIDTH - 120))
	_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_blurb.custom_minimum_size.x = WIDTH - 72
	column.add_child(_blurb)
	column.add_child(_resource)
	_ratings.columns = 2
	_ratings.add_theme_constant_override("h_separation", 30)
	_ratings.add_theme_constant_override("v_separation", 6)
	column.add_child(_ratings)

# Shows `hero_class`, on the right of the screen when `on_right`.
func show_class(hero_class: HeroClass, on_right: bool) -> void:
	_name.text = hero_class.display_name
	_epithet.text = hero_class.epithet
	_blurb.text = hero_class.blurb
	_resource.text = "Resource:  %s" % hero_class.power_name
	_resource.add_theme_color_override("font_color", hero_class.power_colour.lightened(0.25))
	for child in _ratings.get_children():
		_ratings.remove_child(child)
		child.queue_free()
	for rating: String in ["Toughness", "Damage", "Range", "Difficulty"]:
		_ratings.add_child(UiTheme.text(rating, 26, UiTheme.FADED))
		_ratings.add_child(_pips(hero_class.ratings[rating]))
	_card.reset_size()
	var x := get_viewport_rect().size.x - WIDTH - MARGIN if on_right else MARGIN
	var y := (get_viewport_rect().size.y - _card.get_combined_minimum_size().y) * 0.5
	if _slide:
		_slide.kill()
	_slide = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_slide.tween_property(_card, "position", Vector2(x, y), 0.45)

func _pips(lit: int) -> Control:
	var row := Control.new()
	row.custom_minimum_size = Vector2(PIPS * 34, 30)
	row.draw.connect(func() -> void:
		for i in PIPS:
			var centre := Vector2(14 + i * 34, 15)
			var points := PackedVector2Array([centre + Vector2(0, -11), centre + Vector2(11, 0),
				centre + Vector2(0, 11), centre + Vector2(-11, 0)])
			if i < lit:
				row.draw_colored_polygon(points, UiTheme.GOLD)
			else:
				points.append(points[0])
				row.draw_polyline(points, Color(UiTheme.FADED, 0.5), 2.0, true))
	return row
