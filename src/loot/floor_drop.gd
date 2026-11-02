class_name FloorDrop
extends Node3D
# An item or a pile of gold on the floor. It's tossed out of the corpse in a short arc, lands with a
# sound that tells you its rarity before you read it, and stands under a beam of its rarity colour
# (magic and up) with its name floating over it. Drops belong to one player (co-op loot is
# instanced); until co-op that's the only player.

const TOSS_SECONDS := 0.55
const TOSS_HEIGHT := 1.3
const BEAM_HEIGHT := 5.0
const LAND_SOUNDS := {
	Item.Rarity.NORMAL: "drop", Item.Rarity.MAGIC: "drop_magic",
	Item.Rarity.RARE: "drop_rare", Item.Rarity.LEGENDARY: "drop_legendary",
}
const GOLD_COLOUR := Color("e3b45a")
const BEAM_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 colour : source_color;
uniform float strength = 1.0;
void fragment() {
	// Brightest at the floor, gone at the top, and soft at the edges of the cylinder
	float rise = UV.y * UV.y;
	float core = pow(abs(dot(NORMAL, VIEW)), 2.0);
	ALBEDO = colour.rgb * rise * core * strength;
}
"""

# Every drop on the floor, so pickups can look without asking the tree each frame
static var live: Array[FloorDrop] = []
static var _beams := {}
static var _gem_mesh: SphereMesh

var item: Item
var gold := 0
var owner_slot: PlayerSlot
var landed := false
var label := Label3D.new()
var highlighted := false
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _tween: Tween

static func toss_item(parent: Node, dropped: Item, from: Vector3, to: Vector3, slot: PlayerSlot = null) -> FloorDrop:
	var drop := FloorDrop.new()
	drop.item = dropped
	drop.owner_slot = slot
	drop._toss(parent, from, to)
	return drop

static func toss_gold(parent: Node, amount: int, from: Vector3, to: Vector3, slot: PlayerSlot = null) -> FloorDrop:
	var drop := FloorDrop.new()
	drop.gold = amount
	drop.owner_slot = slot
	drop._toss(parent, from, to)
	return drop

func _toss(parent: Node, from: Vector3, to: Vector3) -> void:
	name = "Gold" if item == null else "Drop"
	_from = from
	_to = to
	parent.add_child(self)
	global_position = from
	_tween = create_tween()
	_tween.tween_method(_fly, 0.0, 1.0, TOSS_SECONDS).set_trans(Tween.TRANS_SINE)
	_tween.tween_callback(land)

func _ready() -> void:
	live.append(self)
	_build()

func _exit_tree() -> void:
	live.erase(self)

func is_gold() -> bool:
	return item == null

func belongs_to(slot: PlayerSlot) -> bool:
	return owner_slot == null or owner_slot == slot

func colour() -> Color:
	return GOLD_COLOUR if is_gold() else item.colour()

func _fly(t: float) -> void:
	global_position = _from.lerp(_to, t) + Vector3.UP * sin(PI * t) * TOSS_HEIGHT

# Ends the toss: on the floor, pickable, and it makes its sound
func land() -> void:
	if landed:
		return
	if _tween:
		_tween.kill()
	landed = true
	global_position = _to
	Sound.play("gold" if is_gold() else LAND_SOUNDS[item.rarity])

# Taken off the floor: gone from the list at once, so it can't be picked up twice
func collect() -> void:
	live.erase(self)
	landed = false
	queue_free()

func set_highlighted(on: bool) -> void:
	highlighted = on
	label.scale = Vector3.ONE * (1.3 if on else 1.0)
	label.outline_modulate = Color(colour() * 0.35, 1.0) if on else Color(0, 0, 0, 0.85)

func _build() -> void:
	add_child(_model())
	label.text = "%d Gold" % gold if is_gold() else item.display_name
	label.font = UiTheme.body_font("Bold")
	label.font_size = 36
	label.outline_size = 10
	label.pixel_size = 0.0056
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = colour()
	label.position.y = 0.55
	add_child(label)
	set_highlighted(false)
	if not is_gold() and item.rarity >= Item.Rarity.MAGIC:
		var beam := MeshInstance3D.new()
		beam.name = "Beam"
		beam.mesh = _beam_mesh()
		beam.material_override = _beam_material(item.rarity)
		beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		beam.position.y = BEAM_HEIGHT * 0.5
		add_child(beam)
	if not is_gold() and item.rarity >= Item.Rarity.RARE:
		var glow := OmniLight3D.new()
		glow.light_color = colour()
		glow.light_energy = 1.4 if item.rarity == Item.Rarity.LEGENDARY else 0.9
		glow.omni_range = 2.4
		glow.position.y = 0.4
		add_child(glow)

func _model() -> Node3D:
	if is_gold():
		var stack := "coin_stack_small" if gold < 15 else ("coin_stack_medium" if gold < 40 else "coin_stack_large")
		var coins: Node3D = load("res://assets/kaykit/dungeon/%s.gltf.glb" % stack).instantiate()
		coins.scale = Vector3.ONE * 0.8
		return coins
	if item.base.model:
		# Laid flat on the floor, at whatever angle it fell
		var held: Node3D = item.base.model.instantiate()
		held.rotation_degrees = Vector3(90, randf() * 360.0, 0)
		held.position.y = 0.1
		held.scale = Vector3.ONE * 0.85
		return held
	# Armour and jewellery have no models in the kit: a small glinting gem in the rarity colour
	var gem := MeshInstance3D.new()
	if _gem_mesh == null:
		_gem_mesh = SphereMesh.new()
		_gem_mesh.radius = 0.13
		_gem_mesh.height = 0.34
		_gem_mesh.radial_segments = 4
		_gem_mesh.rings = 1
	gem.mesh = _gem_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = colour()
	material.emission_enabled = true
	material.emission = colour()
	material.emission_energy_multiplier = 0.6
	gem.material_override = material
	gem.position.y = 0.2
	return gem

static func _beam_mesh() -> CylinderMesh:
	if not _beams.has("mesh"):
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.05
		mesh.bottom_radius = 0.11
		mesh.height = BEAM_HEIGHT
		mesh.radial_segments = 8
		mesh.rings = 1
		mesh.cap_top = false
		mesh.cap_bottom = false
		_beams["mesh"] = mesh
	return _beams["mesh"]

static func _beam_material(rarity: int) -> ShaderMaterial:
	if not _beams.has(rarity):
		var material := ShaderMaterial.new()
		material.shader = Shader.new()
		material.shader.code = BEAM_SHADER
		material.set_shader_parameter("colour", Item.RARITY_COLOURS[rarity])
		material.set_shader_parameter("strength", {Item.Rarity.MAGIC: 0.7, Item.Rarity.RARE: 1.0, Item.Rarity.LEGENDARY: 1.6}[rarity])
		_beams[rarity] = material
	return _beams[rarity]
