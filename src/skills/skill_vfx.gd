class_name SkillVfx
extends RefCounted
# The look of the combat kit, in one place: expanding rings on the floor, quick flashes of light,
# one-shot bursts of sparks, and auras that sit under a buffed or chilled combatant. Everything is
# unshaded and additive so glow catches it in the dark, and every piece frees itself when it's done.
# Particle counts stay small for the Deck.

const ARCANE := Color(0.62, 0.36, 1.0)
const FROST := Color(0.5, 0.82, 1.0)
const FURY := Color(1.0, 0.42, 0.16)
const LIFE := Color(0.85, 0.12, 0.1)
const DUST := Color(0.75, 0.62, 0.45)

static var _torus: TorusMesh
static var _disc: CylinderMesh
static var _spark: QuadMesh

# A glowing, see-through material in colour; energy above 1 pushes it into the glow
static func glow_material(colour: Color, energy := 2.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = false
	material.albedo_color = Color(colour.r * energy, colour.g * energy, colour.b * energy, colour.a)
	return material

# A flat ring on the floor at `at`, growing from one radius to another as it fades
static func ring(parent: Node, at: Vector3, from_radius: float, to_radius: float, colour: Color,
		seconds := 0.45, thickness := 0.12) -> MeshInstance3D:
	if _torus == null:
		_torus = TorusMesh.new()
		_torus.inner_radius = 0.88
		_torus.outer_radius = 1.0
		_torus.rings = 32
		_torus.ring_segments = 4
	var mesh := MeshInstance3D.new()
	mesh.mesh = _torus
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := glow_material(colour)
	mesh.material_override = material
	parent.add_child(mesh)
	mesh.global_position = at + Vector3(0, 0.08, 0)
	var start := maxf(from_radius, 0.05)
	mesh.scale = Vector3(start, thickness / 0.12, start)
	var tween := mesh.create_tween().set_parallel()
	tween.tween_property(mesh, "scale", Vector3(to_radius, thickness / 0.12, to_radius), seconds) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(material, "albedo_color:a", 0.0, seconds).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(mesh.queue_free)
	return mesh

# A short burst of light, for glow and to light up the room for a moment
static func flash(parent: Node, at: Vector3, colour: Color, energy := 3.0, reach := 6.0, seconds := 0.35) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.light_color = colour
	light.light_energy = energy
	light.omni_range = reach
	light.shadow_enabled = false
	parent.add_child(light)
	light.global_position = at + Vector3(0, 1.0, 0)
	var tween := light.create_tween()
	tween.tween_property(light, "light_energy", 0.0, seconds).set_ease(Tween.EASE_IN)
	tween.tween_callback(light.queue_free)
	return light

# A one-shot spray of small glowing quads flying out from at
static func burst(parent: Node, at: Vector3, colour: Color, amount := 16, speed := 5.0, seconds := 0.5,
		upward := 0.3) -> GPUParticles3D:
	if _spark == null:
		_spark = QuadMesh.new()
		_spark.size = Vector2(0.12, 0.12)
	var particles := GPUParticles3D.new()
	particles.amount = amount
	particles.lifetime = seconds
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.local_coords = false
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0, upward, 0) if upward > 0.99 else Vector3(1, upward, 0)
	process.spread = 180.0
	process.flatness = 1.0 - upward
	process.initial_velocity_min = speed * 0.5
	process.initial_velocity_max = speed
	process.gravity = Vector3(0, -6.0, 0)
	process.damping_min = speed
	process.damping_max = speed * 1.5
	process.scale_min = 0.6
	process.scale_max = 1.4
	var fade := Gradient.new()
	fade.set_color(0, colour)
	fade.set_color(1, Color(colour, 0.0))
	var fade_texture := GradientTexture1D.new()
	fade_texture.gradient = fade
	process.color_ramp = fade_texture
	particles.process_material = process
	var material := glow_material(Color.WHITE, 2.5)
	material.vertex_color_use_as_albedo = true
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	var quad := _spark.duplicate() as QuadMesh
	quad.material = material
	particles.draw_pass_1 = quad
	parent.add_child(particles)
	particles.global_position = at + Vector3(0, 0.5, 0)
	particles.emitting = true
	particles.finished.connect(particles.queue_free)
	return particles

# A soft glowing disc to sit under a combatant while a status lasts (hand it to Statuses.apply)
static func aura(colour: Color, radius := 0.9) -> MeshInstance3D:
	if _disc == null:
		_disc = CylinderMesh.new()
		_disc.top_radius = 1.0
		_disc.bottom_radius = 1.0
		_disc.height = 0.02
		_disc.radial_segments = 24
		_disc.rings = 1
	var mesh := MeshInstance3D.new()
	mesh.name = "Aura"
	mesh.mesh = _disc
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := glow_material(Color(colour, 0.35), 1.6)
	mesh.material_override = material
	mesh.position.y = 0.05
	mesh.scale = Vector3(radius, 1.0, radius)
	# A slow breathe, so it reads as alive rather than a decal; the tween dies with the mesh
	mesh.ready.connect(func() -> void:
		var tween := mesh.create_tween().set_loops()
		tween.tween_property(material, "albedo_color:a", 0.15, 0.6).set_trans(Tween.TRANS_SINE)
		tween.tween_property(material, "albedo_color:a", 0.35, 0.6).set_trans(Tween.TRANS_SINE), CONNECT_ONE_SHOT)
	return mesh
