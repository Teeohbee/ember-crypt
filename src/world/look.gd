class_name Look
extends RefCounted
# The darker tone, in one place: KayKit's cheerful colours pushed down under a near-black sky, a cold
# blue-grey ambient so shadows aren't pure black, tight warm pools from torches with gloom between
# them, thin volumetric fog for the light to catch in, glow on anything bright, and a vignette closing
# in at the screen's edges. Filmic tonemapping keeps the torches from blowing out. Every 3D scene
# takes its environment from here, so the tone is tuned once.

const AMBIENT := Color("252c3c")
const TORCH := Color("ff9a4a")
const CANDLE := Color("ffb86b")
const MOONLIGHT := Color("8fa3c8")

static func environment() -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("050404")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = AMBIENT
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.9
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.024
	env.volumetric_fog_albedo = Color("8a8f9c")
	env.volumetric_fog_emission = Color("0b0a0e")
	env.volumetric_fog_length = 48.0
	env.volumetric_fog_anisotropy = 0.4
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.6
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.16
	env.adjustment_saturation = 0.78
	return env

# A torch's light: warm, flickering, with soft shadows, falling off steeply so it lights a pool
# rather than the room.
static func torch_light(energy := 3.2, reach := 9.0) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.light_color = TORCH
	light.light_energy = energy * 1.25
	light.omni_range = reach * 0.9
	light.omni_attenuation = 1.9
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

# The light every hero carries, as in Diablo: a small warm pool that walks with them, close and bright
# enough that the hero stands out from the floor and never vanishes into the gloom, with the dark
# always just ahead. It hangs straight overhead, since the hero turns and the camera doesn't. No
# shadows; the torches cast those.
static func hero_light() -> OmniLight3D:
	var light := OmniLight3D.new()
	light.name = "HeroLight"
	light.position = Vector3(0, 2.6, 0)
	light.light_color = Color("ffd9a8")
	light.light_energy = 2.3
	light.omni_range = 6.5
	light.omni_attenuation = 1.8
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

# M6 World

# Outdoors at night: the same grade, but a deep blue-black sky, a colder and slightly brighter ambient
# for the moon, and thicker, bluer fog lying over everything.
static func night_environment(fog := 0.028) -> Environment:
	var env := environment()
	env.background_color = Color("06080e")
	env.ambient_light_color = Color("2c3850")
	env.ambient_light_energy = 0.6
	env.volumetric_fog_density = fog
	env.volumetric_fog_albedo = Color("8d9bb5")
	env.volumetric_fog_emission = Color("0a0d16")
	env.volumetric_fog_length = 40.0
	return env

# The moon: one cold directional light, low and from the north-west so headstones throw long shadows
# toward the camera. Shadows only reach as far as the camera can see, for the Deck.
static func moon(energy := 0.55) -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	light.name = "Moon"
	light.light_color = MOONLIGHT
	light.light_energy = energy
	light.rotation_degrees = Vector3(-38, 150, 0)
	light.shadow_enabled = true
	light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	light.directional_shadow_max_distance = 40.0
	light.light_volumetric_fog_energy = 0.8
	return light

# The screen's edges sinking into darkness, between the world and the HUD
static func vignette() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.name = "Vignette"
	layer.layer = -1
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = _vignette_shader()
	shade.material = material
	layer.add_child(shade)
	return layer

static var _vignette: Shader

static func _vignette_shader() -> Shader:
	if _vignette == null:
		_vignette = Shader.new()
		_vignette.code = """
shader_type canvas_item;
uniform float strength = 0.72;
uniform float inner = 0.42;
void fragment() {
	vec2 size = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 offset = (SCREEN_UV - 0.5) * vec2(size.x / size.y, 1.0);
	float shade = smoothstep(inner, inner + 0.55, length(offset));
	COLOR = vec4(0.0, 0.0, 0.01, shade * strength);
}
"""
	return _vignette
