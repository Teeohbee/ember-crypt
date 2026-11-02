class_name NamePlate
extends Node3D
# An elite's name over its head, in rare yellow, with its affixes underneath and a health bar, the way
# Diablo marks a monster worth worrying about. It floats in world space rather than turning with the
# monster (the camera never rotates, so world x is screen x). Redraws only when health changes.

const RARE := Color("f0cf5a")
const HEIGHT := 2.7
const BAR_WIDTH := 1.4
const BAR_HEIGHT := 0.09

var monster: Monster
var title: Label3D
var subtitle: Label3D
var _fill: MeshInstance3D

func _init(owner_monster: Monster, name_text: String, affix_text: String) -> void:
	name = "NamePlate"
	monster = owner_monster
	top_level = true
	title = _label(name_text, 44, RARE)
	title.position.y = 0.42
	add_child(title)
	subtitle = _label(affix_text, 30, UiTheme.PARCHMENT)
	subtitle.position.y = 0.2
	add_child(subtitle)
	add_child(_bar(Vector3(-BAR_WIDTH * 0.5 - 0.02, 0, -0.01), BAR_WIDTH + 0.04, BAR_HEIGHT + 0.04, Color(0, 0, 0, 0.85), 0))
	_fill = _bar(Vector3(-BAR_WIDTH * 0.5, 0, 0), BAR_WIDTH, BAR_HEIGHT, UiTheme.BLOOD.lightened(0.15), 1)
	add_child(_fill)

func _ready() -> void:
	monster.health_changed.connect(_on_health_changed)
	monster.died.connect(func(_event: DamageEvent) -> void:
		create_tween().tween_property(self, "scale", Vector3(1, 0, 1), 0.3).finished.connect(hide))
	_on_health_changed(monster.health, monster.max_health())
	_follow()

func _process(_delta: float) -> void:
	_follow()

func fraction() -> float:
	return _fill.scale.x

func _follow() -> void:
	global_position = monster.global_position + Vector3(0, HEIGHT * monster.model.scale.y, 0)

func _on_health_changed(health: float, max_health: float) -> void:
	_fill.scale.x = clampf(health / maxf(max_health, 1.0), 0.0, 1.0)

static func _label(words: String, size: int, colour: Color) -> Label3D:
	var label := Label3D.new()
	label.text = words
	label.font = UiTheme.heading_font(700)
	label.font_size = size
	label.pixel_size = 0.006
	label.modulate = colour
	label.outline_modulate = Color(0, 0, 0, 0.9)
	label.outline_size = 10
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.render_priority = 2
	label.outline_render_priority = 1
	return label

# A flat strip that grows rightwards from its left end, so scaling x empties it from the right
static func _bar(left: Vector3, width: float, height: float, colour: Color, priority: int) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = Vector2(width, height)
	quad.center_offset = Vector3(width * 0.5, 0, 0)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.billboard_keep_scale = true
	material.no_depth_test = true
	material.render_priority = priority
	material.albedo_color = colour
	quad.material = material
	var bar := MeshInstance3D.new()
	bar.mesh = quad
	bar.position = left
	bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return bar
