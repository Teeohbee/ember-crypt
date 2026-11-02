class_name WallFade
extends Node
# Walls between the camera and a hero dissolve, so nobody vanishes behind the crypt. A few times a
# second each occluder (anything in the "occluders" group; CryptKit's walls join it) is tested against
# the line from the camera to each hero. Ones in the way are drawn with a dithered material that
# throws away more pixels the more faded it is, so they stay opaque to the renderer (no sorting, still
# casting shadows) yet read as see-through. Walls not in the way get their own materials back.

const GROUP := &"occluders"
const CHECK_SECONDS := 0.1
const FADED := 0.7               # fraction of pixels dropped when fully faded
const FADE_SPEED := 4.0          # per second
const CHEST := Vector3(0, 1.2, 0)

const SHADER := """
shader_type spatial;
render_mode cull_back;
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
instance uniform float fade = 0.0;
void fragment() {
	// 4x4 ordered dither: a steady pattern of dropped pixels, no noise to shimmer
	int x = int(FRAGCOORD.x) % 4;
	int y = int(FRAGCOORD.y) % 4;
	float bayer[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	if ((bayer[y * 4 + x] + 0.5) / 16.0 < fade) {
		discard;
	}
	ALBEDO = texture(albedo_texture, UV).rgb;
	ROUGHNESS = 0.9;
}
"""

# One dithered material per atlas texture the occluders use
static var _materials := {}
static var _shader: Shader

var camera: Camera3D
# occluder -> current fade, 0-1 of FADED
var fading := {}
var _blocking := {}
var _check_in := 0.0

# The dithered stand-in for a mesh's own material, sharing its texture
static func material_for(mesh: MeshInstance3D) -> ShaderMaterial:
	var own := mesh.get_active_material(0) as BaseMaterial3D
	var texture: Texture2D = own.albedo_texture if own else null
	if not _materials.has(texture):
		if _shader == null:
			_shader = Shader.new()
			_shader.code = SHADER
		var dithered := ShaderMaterial.new()
		dithered.shader = _shader
		dithered.set_shader_parameter(&"albedo_texture", texture)
		_materials[texture] = dithered
	return _materials[texture]

func _init(owner_camera: Camera3D = null) -> void:
	name = "WallFade"
	camera = owner_camera

func _process(delta: float) -> void:
	_check_in -= delta
	if _check_in <= 0.0 and camera:
		_check_in = CHECK_SECONDS
		var targets: Array[Vector3] = []
		for hero in Session.heroes():
			targets.append(hero.global_position + CHEST)
		check(camera.global_position, targets)
	step(delta)

# Works out which occluders stand between eye and any of targets
func check(eye: Vector3, targets: Array[Vector3]) -> void:
	_blocking.clear()
	for node in get_tree().get_nodes_in_group(GROUP):
		var occluder := node as Node3D
		if occluder == null:
			continue
		var box := bounds_of(occluder)
		for target in targets:
			if box.intersects_segment(eye, target):
				_blocking[occluder] = true
				if not fading.has(occluder):
					fading[occluder] = 0.0
					_set_override(occluder, true)
				break

# Moves each fade toward where it should be, handing back materials once a wall is solid again
func step(delta: float) -> void:
	for occluder: Variant in fading.keys():
		if not is_instance_valid(occluder):
			fading.erase(occluder)
			continue
		var goal := 1.0 if _blocking.has(occluder) else 0.0
		var amount := move_toward(fading[occluder], goal, FADE_SPEED * delta)
		fading[occluder] = amount
		for mesh: GeometryInstance3D in _meshes(occluder):
			mesh.set_instance_shader_parameter(&"fade", amount * FADED)
		if amount <= 0.0 and goal == 0.0:
			_set_override(occluder, false)
			fading.erase(occluder)

func faded(occluder: Node3D) -> float:
	return fading.get(occluder, 0.0)

# The occluder's world-space box, worked out once: walls don't move
static func bounds_of(occluder: Node3D) -> AABB:
	if not occluder.has_meta(&"occluder_bounds"):
		var box := AABB()
		var first := true
		for mesh: MeshInstance3D in _meshes(occluder):
			var world := mesh.global_transform * mesh.get_aabb()
			box = world if first else box.merge(world)
			first = false
		occluder.set_meta(&"occluder_bounds", box)
	return occluder.get_meta(&"occluder_bounds")

static func _meshes(occluder: Node3D) -> Array:
	if not occluder.has_meta(&"occluder_meshes"):
		var found := occluder.find_children("*", "MeshInstance3D", true, false)
		if occluder is MeshInstance3D:
			found.append(occluder)
		occluder.set_meta(&"occluder_meshes", found)
	return occluder.get_meta(&"occluder_meshes")

static func _set_override(occluder: Node3D, dithered: bool) -> void:
	for mesh: MeshInstance3D in _meshes(occluder):
		if dithered:
			mesh.material_override = material_for(mesh)
		else:
			mesh.material_override = null
			mesh.set_instance_shader_parameter(&"fade", 0.0)
