class_name ArcaneMissile
extends Area3D
# One Magic Missile in flight: a glowing violet bolt with a light and a short sparking trail. It curls
# toward its target (turning faster the closer it gets, so it never orbits), strikes the first enemy it
# touches, flares and goes out. Bolts are pooled: one that has gone out waits to be fired again.

const RADIUS := 0.35
const HEIGHT := 1.25
const FLARE_SECONDS := 0.14
const COLOUR := Color(0.62, 0.48, 1.0)

static var _idle: Array[ArcaneMissile] = []
static var _mesh: SphereMesh
static var _trail_mesh: QuadMesh
static var _trail_process: ParticleProcessMaterial

var caster: Combatant
var skill: SkillDef
var target: Combatant
var direction := Vector3.FORWARD
var flying: bool:
	get: return _life > 0.0

var _speed := 20.0
var _turn := 7.0
var _life := 0.0
var _flare := 0.0
var _core := MeshInstance3D.new()
var _light := OmniLight3D.new()
var _trail := GPUParticles3D.new()

# Sends a bolt from caster along aim, curling toward target if there is one
static func fire(from: Combatant, with_skill: SkillDef, at: Combatant, aim: Vector3) -> ArcaneMissile:
	var missile: ArcaneMissile = null
	while missile == null and not _idle.is_empty():
		var candidate: ArcaneMissile = _idle.pop_back()
		if is_instance_valid(candidate) and not candidate.is_queued_for_deletion():
			missile = candidate
	if missile == null:
		missile = ArcaneMissile.new()
	var parent := from.get_parent()
	if missile.get_parent() != parent:
		if missile.get_parent():
			missile.get_parent().remove_child(missile)
		parent.add_child(missile)
	missile.launch(from, with_skill, at, aim)
	return missile

static func idle_count() -> int:
	return _idle.size()

func _init() -> void:
	name = "ArcaneMissile"
	top_level = true
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = RADIUS
	shape.shape = sphere
	add_child(shape)
	_build_look()
	body_entered.connect(_on_body_entered)
	visible = false
	monitoring = false
	set_physics_process(false)

func launch(from: Combatant, with_skill: SkillDef, at: Combatant, aim: Vector3) -> void:
	caster = from
	skill = with_skill
	target = at
	aim.y = 0.0
	direction = aim.normalized() if aim.length_squared() > 0.0001 else from.facing()
	_speed = skill.params.get("speed", 20.0)
	_turn = skill.params.get("turn", 7.0)
	_life = skill.params.get("life", 1.1)
	_flare = 0.0
	global_position = from.global_position + Vector3(0, HEIGHT, 0) + direction * 0.7
	_core.scale = Vector3.ONE
	_light.light_energy = 2.0
	visible = true
	_trail.restart()
	_trail.emitting = true
	set_deferred(&"monitoring", true)
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if _flare > 0.0:
		_flare -= delta
		var through := 1.0 - maxf(_flare, 0.0) / FLARE_SECONDS
		_core.scale = Vector3.ONE * (1.0 + 2.5 * through)
		_light.light_energy = 6.0 * (1.0 - through)
		if _flare <= 0.0:
			_go_out()
		return
	_life -= delta
	if _life <= 0.0:
		_flare_out()
		return
	if is_instance_valid(target) and target.alive:
		var to_target := target.global_position + Vector3(0, HEIGHT, 0) - global_position
		var distance := to_target.length()
		if distance <= RADIUS + 0.45:
			_strike(target)
			return
		# Turn harder up close, so a near miss bends in rather than circling
		var turn := _turn * (1.0 + 4.0 / maxf(distance, 0.5))
		direction = direction.slerp(to_target / distance, minf(turn * delta, 1.0)).normalized()
	global_position += direction * _speed * delta

func _on_body_entered(body: Node3D) -> void:
	if flying and _flare <= 0.0 and body is Combatant and is_instance_valid(caster) and body.team != caster.team and body.alive:
		_strike(body)

func _strike(hit: Combatant) -> void:
	if is_instance_valid(caster):
		Combat.hit(caster, hit, skill)
	_flare_out()

func _flare_out() -> void:
	_life = 0.0
	_flare = FLARE_SECONDS
	_trail.emitting = false
	set_deferred(&"monitoring", false)

func _go_out() -> void:
	_life = 0.0
	_flare = 0.0
	visible = false
	target = null
	set_physics_process(false)
	set_deferred(&"monitoring", false)
	if not _idle.has(self):
		_idle.append(self)

func _build_look() -> void:
	if _mesh == null:
		_mesh = SphereMesh.new()
		_mesh.radius = 0.13
		_mesh.height = 0.26
		_mesh.radial_segments = 12
		_mesh.rings = 6
		var glow := StandardMaterial3D.new()
		glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow.albedo_color = COLOUR * 2.6   # over 1, so the glow picks it up
		_mesh.material = glow
		_trail_mesh = QuadMesh.new()
		_trail_mesh.size = Vector2(0.18, 0.18)
		var spark := StandardMaterial3D.new()
		spark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		spark.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		spark.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		spark.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		spark.vertex_color_use_as_albedo = true
		spark.albedo_texture = Look._soft_dot()
		spark.albedo_color = Color(2.0, 2.0, 2.0)
		_trail_mesh.material = spark
		_trail_process = ParticleProcessMaterial.new()
		_trail_process.gravity = Vector3.ZERO
		_trail_process.spread = 180.0
		_trail_process.initial_velocity_min = 0.1
		_trail_process.initial_velocity_max = 0.4
		_trail_process.scale_min = 0.6
		_trail_process.scale_max = 1.0
		var fade := Gradient.new()
		fade.set_color(0, Color(COLOUR, 0.9))
		fade.set_color(1, Color(0.3, 0.15, 0.8, 0.0))
		var fade_texture := GradientTexture1D.new()
		fade_texture.gradient = fade
		_trail_process.color_ramp = fade_texture
	_core.mesh = _mesh
	_core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_core)
	_light.light_color = COLOUR
	_light.omni_range = 3.5
	_light.light_energy = 2.0
	add_child(_light)
	_trail.amount = 20
	_trail.lifetime = 0.28
	_trail.local_coords = false
	_trail.process_material = _trail_process
	_trail.draw_pass_1 = _trail_mesh
	_trail.emitting = false
	add_child(_trail)
