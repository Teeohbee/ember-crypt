class_name UiTheme
extends RefCounted
# The look of every menu: soot-black panels in a tarnished bronze fretwork frame, parchment text, and gold for
# whatever has focus. Cinzel for headings, Alegreya Sans for everything you read. Built in code and
# merged into Godot's default theme at boot: a theme on the root window doesn't reach Controls under
# a CanvasLayer, which is where all the UI lives.

const VOID := Color("0a0807")
const SOOT := Color("15100d")
const ASH := Color("2a211b")
const BRONZE := Color("6e5233")
const GOLD := Color("e3b45a")
const EMBER := Color("d9662a")
const BLOOD := Color("8e2a22")
const PARCHMENT := Color("e8dcc4")
const FADED := Color("9c8f7c")
const DISABLED := Color("5a5047")

const BODY_SIZE := 30

const PANEL_FRAME := "res://assets/ui_frames/panel.png"
const SLOT_FRAME := "res://assets/ui_frames/slot_edge.png"
# Pixels at each corner of a frame texture that don't stretch
const FRAME_CORNER := 24

static var _heading: Font
# Frame textures, loaded once and held: a stylebox built in a _draw() is gone before the frame renders,
# and a texture nothing else holds goes with it, leaving the border drawn as a solid block
static var _frames := {}
static var _fonts := {}

static func heading_font(weight := 700) -> Font:
	if _heading == null:
		_heading = load("res://assets/fonts/Cinzel-Variable.ttf")
	var variation := FontVariation.new()
	variation.base_font = _heading
	variation.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	return variation

static func body_font(weight := "Medium") -> Font:
	if not _fonts.has(weight):
		_fonts[weight] = load("res://assets/fonts/AlegreyaSans-%s.ttf" % weight)
	return _fonts[weight]

static func install() -> void:
	var fallback := ThemeDB.get_default_theme()
	fallback.merge_with(build())
	fallback.default_font = body_font()
	fallback.default_font_size = BODY_SIZE
	ThemeDB.fallback_font = body_font()
	ThemeDB.fallback_font_size = BODY_SIZE

static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font = body_font()
	theme.default_font_size = BODY_SIZE

	theme.set_color("font_color", "Label", PARCHMENT)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.6))
	theme.set_constant("shadow_offset_y", "Label", 2)

	# Menu buttons are words until they have focus; then a dark band with a gold underline sits behind
	var clear := StyleBoxEmpty.new()
	clear.content_margin_left = 28
	clear.content_margin_right = 28
	clear.content_margin_top = 6
	clear.content_margin_bottom = 8
	var lit := StyleBoxFlat.new()
	lit.bg_color = Color(BLOOD, 0.35)
	lit.border_color = GOLD
	lit.border_width_bottom = 2
	lit.content_margin_left = 28
	lit.content_margin_right = 28
	lit.content_margin_top = 6
	lit.content_margin_bottom = 8
	lit.shadow_color = Color(EMBER, 0.18)
	lit.shadow_size = 14
	for state in ["normal", "disabled", "pressed"]:
		theme.set_stylebox(state, "Button", clear)
	for state in ["focus", "hover", "hover_pressed"]:
		theme.set_stylebox(state, "Button", lit)
	theme.set_font("font", "Button", heading_font(600))
	theme.set_font_size("font_size", "Button", 38)
	theme.set_color("font_color", "Button", FADED)
	theme.set_color("font_focus_color", "Button", GOLD)
	theme.set_color("font_hover_color", "Button", GOLD)
	theme.set_color("font_pressed_color", "Button", GOLD)
	theme.set_color("font_hover_pressed_color", "Button", GOLD)
	theme.set_color("font_disabled_color", "Button", DISABLED)

	theme.set_stylebox("panel", "PanelContainer", panel())
	theme.set_stylebox("panel", "Panel", panel())
	return theme

# Soot panel in a bronze fretwork frame (Kenney's Fantasy UI Borders, recoloured), stretched by its middle
static func panel() -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = frame(PANEL_FRAME)
	box.set_texture_margin_all(FRAME_CORNER)
	box.set_content_margin_all(36)
	return box

static func frame(path: String) -> Texture2D:
	if not _frames.has(path):
		_frames[path] = load(path)
	return _frames[path]

# A slot's frame edge, white so it can be tinted by rarity or focus; draw the fill under it
static func slot_edge() -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = frame(SLOT_FRAME)
	box.set_texture_margin_all(FRAME_CORNER)
	box.draw_center = false
	return box

static func heading(text: String, size := 56, colour := GOLD) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", heading_font())
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	return label

static func text(words: String, size := BODY_SIZE, colour := PARCHMENT) -> Label:
	var label := Label.new()
	label.text = words
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	return label

# A thin bronze rule with a diamond in the middle, for under headings.
static func divider(width := 420.0) -> Control:
	var rule := Control.new()
	rule.custom_minimum_size = Vector2(width, 18)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rule.draw.connect(func() -> void:
		var middle := rule.size * 0.5
		rule.draw_line(Vector2(0, middle.y), Vector2(middle.x - 12, middle.y), BRONZE, 2.0, true)
		rule.draw_line(Vector2(middle.x + 12, middle.y), Vector2(rule.size.x, middle.y), BRONZE, 2.0, true)
		rule.draw_colored_polygon(PackedVector2Array([middle + Vector2(0, -7), middle + Vector2(7, 0),
			middle + Vector2(0, 7), middle + Vector2(-7, 0)]), GOLD))
	return rule
