class_name LevelUpBurst
extends Node3D
# The level-up fanfare in the world: a shaft of gold light rises through the hero, a ring sweeps out
# across the floor and a warm light swells and fades, with the level-up toll. A second and a half, then
# it frees itself. Level-ups are rare, so it's built fresh each time rather than pooled.

const SECONDS := 1.6
const GOLD := Color(1.0, 0.78, 0.35)

# Unshaded and additive; fades towards the top and with `fade`, so the shaft has no hard edges
const SHAFT_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 colour : source_color = vec4(1.0, 0.78, 0.35, 1.0);
uniform float fade = 1.0;
void fragment() {
	float rise = 1.0 - UV.y;
	float edge = 1.0 - abs(UV.x * 2.0 - 1.0);
	ALBEDO = colour.rgb * 2.5;
	ALPHA = clamp(fade * pow(1.0 - rise, 1.5) * (0.5 + 0.5 * edge), 0.0, 1.0);
}
"""

var shaft := MeshInstance3D.new()
var ring := MeshInstance3D.new()
var light := OmniLight3D.new()

func _init() -> void:
	name = "LevelUpBurst"
	var material := ShaderMaterial.new()
	material.shader = Shader.new()
	material.shader.code = SHAFT_SHADER
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.7
	cylinder.bottom_radius = 0.9
	cylinder.height = 7.0
	cylinder.cap_top = false
	cylinder.cap_bottom = false
	cylinder.radial_segments = 24
	cylinder.rings = 1
	shaft.mesh = cylinder
	shaft.material_override = material
	shaft.position.y = 3.5
	shaft.scale = Vector3(0.2, 1.0, 0.2)
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shaft)
	var torus := TorusMesh.new()
	torus.inner_radius = 0.9
	torus.outer_radius = 1.0
	torus.rings = 32
	torus.ring_segments = 6
	var ring_material := StandardMaterial3D.new()
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	ring_material.albedo_color = GOLD
	ring.mesh = torus
	ring.material_override = ring_material
	ring.position.y = 0.05
	ring.scale = Vector3(0.3, 0.2, 0.3)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
	light.light_color = GOLD
	light.light_energy = 0.0
	light.omni_range = 7.0
	light.position.y = 1.6
	add_child(light)

func _ready() -> void:
	Sound.play("level_up")
	var material: ShaderMaterial = shaft.material_override
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(shaft, "scale", Vector3.ONE, 0.35)
	tween.tween_property(light, "light_energy", 6.0, 0.25)
	tween.tween_property(ring, "scale", Vector3(5.0, 0.2, 5.0), 0.9)
	tween.tween_property(ring.material_override, "albedo_color:a", 0.0, 0.9)
	tween.chain().tween_method(func(fade: float) -> void: material.set_shader_parameter("fade", fade), 1.0, 0.0, SECONDS - 0.35)
	tween.parallel().tween_property(light, "light_energy", 0.0, SECONDS - 0.35)
	tween.chain().tween_callback(queue_free)
