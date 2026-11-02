class_name ArcaneOrb
extends Node3D
# One Arcane Orb in flight: a glowing violet ball with its own small light, drifting along a flat line.
# It bursts when it comes within reach of an enemy, hits a wall, or runs out of range; the burst hurts
# everything within the skill's radius. Steps in physics frames, so a test can drive it by hand. One
# orb at a time is the most Arcane Power allows, so these aren't pooled.

const HEIGHT := 1.0
# How close an enemy has to come to set it off
const TRIGGER := 0.8

static var _mesh: SphereMesh

var caster: Combatant
var skill: SkillDef
var direction: Vector3
var speed := 7.0
var max_range := 14.0
var burst := false
var _travelled := 0.0
var _query: PhysicsRayQueryParameters3D

func _init(owner_caster: Combatant, orb_skill: SkillDef, flat_direction: Vector3) -> void:
	name = "ArcaneOrb"
	caster = owner_caster
	skill = orb_skill
	direction = flat_direction.normalized()
	speed = float(orb_skill.params.get("speed", 7.0))
	max_range = float(orb_skill.params.get("range", 14.0))
	if _mesh == null:
		_mesh = SphereMesh.new()
		_mesh.radius = 0.32
		_mesh.height = 0.64
		_mesh.radial_segments = 16
		_mesh.rings = 8
	var ball := MeshInstance3D.new()
	ball.mesh = _mesh
	ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ball.material_override = SkillVfx.glow_material(SkillVfx.ARCANE, 3.0)
	add_child(ball)
	var light := OmniLight3D.new()
	light.light_color = SkillVfx.ARCANE
	light.light_energy = 1.6
	light.omni_range = 4.0
	add_child(light)

func _ready() -> void:
	_query = PhysicsRayQueryParameters3D.new()
	var exclude: Array[RID] = []
	for node in get_tree().get_nodes_in_group(Combatant.TEAM_GROUPS[caster.team]):
		if node is CollisionObject3D:
			exclude.append(node.get_rid())
	_query.exclude = exclude

func _physics_process(delta: float) -> void:
	if burst:
		return
	if not is_instance_valid(caster):
		queue_free()
		return
	var step := minf(speed * delta, max_range - _travelled)
	var from := global_position
	var to := from + direction * step
	_query.from = from
	_query.to = to
	var hit := get_world_3d().direct_space_state.intersect_ray(_query)
	if not hit.is_empty():
		global_position = hit.position - direction * 0.2
		_burst()
		return
	global_position = to
	_travelled += step
	if _enemy_in_reach() or _travelled >= max_range - 0.001:
		_burst()

func _enemy_in_reach() -> bool:
	for enemy in caster.hostiles():
		var offset := enemy.global_position - global_position
		offset.y = 0
		if offset.length() <= TRIGGER:
			return true
	return false

func _burst() -> void:
	burst = true
	var ground := Vector3(global_position.x, global_position.y - HEIGHT, global_position.z)
	for victim in Targeting.in_radius(ground, caster.hostiles(), skill.radius):
		Combat.hit(caster, victim, skill)
	var world := get_parent()
	Sound.play("orb_burst", randf_range(0.95, 1.05))
	SkillVfx.ring(world, ground, 0.3, skill.radius, SkillVfx.ARCANE, 0.4, 0.2)
	SkillVfx.burst(world, ground + Vector3(0, 0.5, 0), SkillVfx.ARCANE, 20, 5.0, 0.5, 0.6)
	SkillVfx.flash(world, ground, SkillVfx.ARCANE, 3.0, 7.0, 0.35)
	Feedback.shake(0.3)
	queue_free()
