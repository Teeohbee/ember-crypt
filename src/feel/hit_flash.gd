class_name HitFlash
extends Node
# The white blink and squash on whatever was hit. KayKit meshes share one material per atlas, so the
# flash can't touch it; instead each mesh of the hit combatant gets a shared additive overlay for a
# moment, its strength an instance uniform, and the model is squashed and springs back. The overlay is
# taken off again afterwards so nothing pays for an extra pass while it isn't flashing.

const SECONDS := 0.14
const SQUASH := 0.14
const WHITE := Color(1.0, 0.95, 0.85)
const RED := Color(1.0, 0.18, 0.12)

const SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled;
instance uniform float flash = 0.0;
instance uniform vec4 tint : source_color = vec4(1.0);
void fragment() {
	ALBEDO = tint.rgb * flash;
}
"""

static var _overlay: ShaderMaterial

# Parallel lists of what's flashing: the combatant and its seconds left
var _targets: Array[Node3D] = []
var _left := PackedFloat32Array()

static func overlay() -> ShaderMaterial:
	if _overlay == null:
		_overlay = ShaderMaterial.new()
		_overlay.shader = Shader.new()
		_overlay.shader.code = SHADER
	return _overlay

func _init() -> void:
	name = "HitFlash"
	process_mode = Node.PROCESS_MODE_PAUSABLE

func flash(target: Node3D, tint := WHITE) -> void:
	if not is_instance_valid(target):
		return
	# Found afresh each hit: gear swaps change what's in the hands
	target.remove_meta(&"flash_meshes")
	for mesh: GeometryInstance3D in meshes_of(target):
		mesh.material_overlay = overlay()
		mesh.set_instance_shader_parameter(&"tint", tint)
	var i := _targets.find(target)
	if i < 0:
		_targets.append(target)
		_left.append(SECONDS)
	else:
		_left[i] = SECONDS
	_apply(target, 1.0)

func flashing(target: Node3D) -> bool:
	return _targets.has(target)

func _process(delta: float) -> void:
	for i in range(_targets.size() - 1, -1, -1):
		var target := _targets[i]
		_left[i] -= delta
		if not is_instance_valid(target):
			_forget(i)
		elif _left[i] <= 0.0:
			_apply(target, 0.0)
			for mesh: GeometryInstance3D in meshes_of(target):
				if is_instance_valid(mesh):
					mesh.material_overlay = null
			_forget(i)
		else:
			_apply(target, _left[i] / SECONDS)

func _forget(i: int) -> void:
	_targets.remove_at(i)
	_left.remove_at(i)

func _apply(target: Node3D, strength: float) -> void:
	for mesh: GeometryInstance3D in meshes_of(target):
		if is_instance_valid(mesh):
			mesh.set_instance_shader_parameter(&"flash", strength * strength)
	var model := _model_of(target)
	if model:
		var base: Vector3 = model.get_meta(&"base_scale", model.scale)
		if not model.has_meta(&"base_scale"):
			model.set_meta(&"base_scale", base)
		var squash := SQUASH * strength
		model.scale = base * Vector3(1.0 + squash, 1.0 - squash, 1.0 + squash)

# The combatant's meshes, found when the flash starts and kept on it until the next
static func meshes_of(target: Node3D) -> Array:
	if not target.has_meta(&"flash_meshes"):
		var root: Node = _model_of(target)
		var found := (root if root else target).find_children("*", "MeshInstance3D", true, false)
		target.set_meta(&"flash_meshes", found.filter(func(mesh: Node) -> bool: return not mesh.is_queued_for_deletion()))
	return target.get_meta(&"flash_meshes")

static func _model_of(target: Node3D) -> Node3D:
	var model: Variant = target.get(&"model")
	return model as Node3D if model is Node3D else null
