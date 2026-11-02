class_name Look
extends RefCounted
# The darker tone, in one place: KayKit's cheerful colours pushed down under a near-black sky, a cold
# blue-grey ambient so shadows aren't pure black, warm pools from torches, thin volumetric fog for
# the light to catch in, and glow on anything bright. Filmic tonemapping keeps the torches from
# blowing out. Every 3D scene takes its environment from here, so the tone is tuned once.

const AMBIENT := Color("2b3240")
const TORCH := Color("ff9a4a")
const CANDLE := Color("ffb86b")
const MOONLIGHT := Color("8fa3c8")

static func environment() -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("050404")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = AMBIENT
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.9
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.018
	env.volumetric_fog_albedo = Color("8a8f9c")
	env.volumetric_fog_emission = Color("0b0a0e")
	env.volumetric_fog_length = 48.0
	env.volumetric_fog_anisotropy = 0.4
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.6
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 0.82
	return env

# A torch's light: warm, flickering, with soft shadows.
static func torch_light(energy := 3.2, reach := 9.0) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.light_color = TORCH
	light.light_energy = energy
	light.omni_range = reach
	light.omni_attenuation = 1.4
	light.shadow_enabled = true
	light.light_volumetric_fog_energy = 1.5
	light.set_script(Flicker)
	return light

# A small fire for a torch head: additive billboards that rise, shrink and cool from yellow to red.
# KayKit's flames are flat atlas colour, so this sits on top and gives glow something to catch.
static func flame(at: Vector3, scale := 1.0) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.position = at
	particles.amount = 24
	particles.lifetime = 0.55
	particles.local_coords = false
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.06 * scale
	process.direction = Vector3.UP
	process.spread = 12.0
	process.initial_velocity_min = 0.5 * scale
	process.initial_velocity_max = 0.9 * scale
	process.gravity = Vector3(0, 0.6, 0)
	process.scale_min = 0.7
	process.scale_max = 1.1
	var shrink := Curve.new()
	shrink.add_point(Vector2(0, 1))
	shrink.add_point(Vector2(1, 0.1))
	var shrink_texture := CurveTexture.new()
	shrink_texture.curve = shrink
	process.scale_curve = shrink_texture
	var cooling := Gradient.new()
	cooling.set_color(0, Color(1.0, 0.85, 0.45, 1.0))
	cooling.add_point(0.45, Color(1.0, 0.45, 0.12, 0.8))
	cooling.set_color(cooling.get_point_count() - 1, Color(0.6, 0.1, 0.03, 0.0))
	var cooling_texture := GradientTexture1D.new()
	cooling_texture.gradient = cooling
	process.color_ramp = cooling_texture
	particles.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2(0.22, 0.3) * scale
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = _soft_dot()
	material.albedo_color = Color(2.2, 2.2, 2.2)   # over 1, so glow picks it up
	quad.material = material
	particles.draw_pass_1 = quad
	return particles

static var _dot: Texture2D

static func _soft_dot() -> Texture2D:
	if _dot == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color.WHITE)
		gradient.set_color(1, Color(1, 1, 1, 0))
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(0.5, 0.0)
		texture.width = 64
		texture.height = 64
		_dot = texture
	return _dot

# The light every hero carries, as in Diablo: a warm pool a few metres across that walks with them,
# so they never vanish into the gloom and the dark is always just ahead. No shadows; the torches cast those.
static func hero_light() -> OmniLight3D:
	var light := OmniLight3D.new()
	light.name = "HeroLight"
	light.position = Vector3(0, 3.0, 0.5)
	light.light_color = Color("ffd9a8")
	light.light_energy = 1.6
	light.omni_range = 8.0
	light.omni_attenuation = 1.2
	light.light_volumetric_fog_energy = 0.4
	return light

# A shaft of cold light from above, for picking something out of the dark.
static func spotlight(colour := MOONLIGHT, energy := 6.0, angle := 22.0) -> SpotLight3D:
	var light := SpotLight3D.new()
	light.light_color = colour
	light.light_energy = energy
	light.spot_range = 14.0
	light.spot_angle = angle
	light.spot_angle_attenuation = 0.6
	light.shadow_enabled = true
	light.light_volumetric_fog_energy = 2.5
	return light
