class_name ShieldingAffix
extends Node
# Shielding: once it's fighting, every so often it throws up a bubble and takes no damage until it
# drops. The bubble is the tell: back off, or hit something else, while it's up.

const EVERY := 8.0
const LASTS := 3.0

var monster: Monster
var bubble: MeshInstance3D
var _clock := 0.0

static var _mesh: SphereMesh

func _init(owner_monster: Monster) -> void:
	name = "Shielding"
	monster = owner_monster
	if _mesh == null:
		_mesh = SphereMesh.new()
		_mesh.radius = 1.15
		_mesh.height = 2.3
		_mesh.radial_segments = 24
		_mesh.rings = 12
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.albedo_color = Color(0.35, 0.55, 1.0, 0.35)
		material.rim_enabled = false
		_mesh.material = material
	bubble = MeshInstance3D.new()
	bubble.mesh = _mesh
	bubble.position.y = 1.0
	bubble.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bubble.visible = false

func _ready() -> void:
	monster.add_child(bubble)
	monster.died.connect(func(_event: DamageEvent) -> void: _set_shielded(false))

func _physics_process(delta: float) -> void:
	if not monster.alive or monster.brain.target == null:
		return
	_clock += delta
	if not monster.brain.immune and _clock >= EVERY:
		_set_shielded(true)
	elif monster.brain.immune and _clock >= EVERY + LASTS:
		_clock = 0.0
		_set_shielded(false)

func _set_shielded(on: bool) -> void:
	monster.brain.immune = on
	bubble.visible = on
	if on:
		Sound.play("shield")
