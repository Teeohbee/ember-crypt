class_name Telegraph
extends MeshInstance3D
# A warning painted on the floor before a big attack lands: the outline of where it will hit, filling
# from the middle out until the moment it does. Rings for circles, wedges for cones. One shared
# material; progress and colour are per-instance shader uniforms, so a telegraph costs a draw call
# and nothing else.

const DANGER := Color(1.0, 0.28, 0.12, 0.9)
const SUMMON := Color(0.62, 0.38, 1.0, 0.8)
const FIRE := Color(1.0, 0.5, 0.1, 0.9)

const SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
instance uniform float progress = 0.0;
instance uniform float half_arc = 3.1416;
instance uniform vec4 tint : source_color = vec4(1.0, 0.3, 0.1, 0.9);
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = abs(atan(p.x, p.y));
	if (r > 1.0 || a > half_arc) discard;
	float rim = smoothstep(0.9, 0.96, r);
	float side = half_arc < 3.1 ? 1.0 - smoothstep(0.0, 0.05, (half_arc - a) * r) : 0.0;
	float fill = r <= progress ? 0.38 : 0.1;
	ALBEDO = tint.rgb * 2.0;
	ALPHA = max(fill, max(rim, side) * 0.95) * tint.a;
}
"""
const PROGRESS := &"progress"

static var _material: ShaderMaterial
static var _plane: PlaneMesh

var seconds := 1.0
var radius := 1.0
var _elapsed := 0.0

# A circle of radius metres at a point on the floor, filling over seconds
static func ring(at: Vector3, ring_radius: float, duration: float, colour := DANGER) -> Telegraph:
	return Telegraph.new(at, 0.0, ring_radius, 360.0, duration, colour)

# A wedge of arc degrees out to radius, pointing at yaw (radians, as Node3D.rotation.y)
static func cone(at: Vector3, yaw: float, cone_radius: float, arc: float, duration: float, colour := DANGER) -> Telegraph:
	return Telegraph.new(at, yaw, cone_radius, arc, duration, colour)

func _init(at: Vector3, yaw: float, size: float, arc: float, duration: float, colour: Color) -> void:
	name = "Telegraph"
	seconds = maxf(duration, 0.05)
	radius = size
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = Shader.new()
		_material.shader.code = SHADER
		_plane = PlaneMesh.new()
		_plane.size = Vector2(2.0, 2.0)
	mesh = _plane
	scale = Vector3(size, 1.0, size)
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	position = at + Vector3(0, 0.04, 0)
	rotation.y = yaw
	set_instance_shader_parameter(&"half_arc", deg_to_rad(arc) * 0.5)
	set_instance_shader_parameter(&"tint", colour)

func _process(delta: float) -> void:
	_elapsed += delta
	set_instance_shader_parameter(PROGRESS, clampf(_elapsed / seconds, 0.0, 1.0))
	if _elapsed >= seconds:
		queue_free()
