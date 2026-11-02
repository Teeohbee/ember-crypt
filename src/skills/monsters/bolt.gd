class_name Bolt
extends Node3D
# A monster's missile: flies straight and flat, hits the first hostile it passes through, and fades
# out at the end of its range. Who it can hit is fixed when it's loosed (heroes don't come and go
# mid-flight), so flying it allocates nothing. Doesn't stop at walls yet: zones have no wall
# collision until M6.

const HIT_RADIUS := 0.6
const HEIGHT := 1.0

static var _meshes := {}

var caster: Combatant
var skill: SkillDef
var direction: Vector3
var speed := 14.0
var _left := 0.0
var _targets: Array[Combatant]

func _init(from: Combatant, with: SkillDef, heading: Vector3) -> void:
	caster = from
	skill = with
	direction = heading.normalized()
	speed = float(skill.params.get("speed", 14.0))
	_left = float(skill.params.get("range", skill.reach + 4.0))
	_targets = from.hostiles()
	add_child(_model(String(skill.params.get("look", "quarrel"))))

func _ready() -> void:
	look_at(global_position + direction, Vector3.UP, true)

func _physics_process(delta: float) -> void:
	var step := speed * delta
	global_position += direction * step
	_left -= step
	for target in _targets:
		if is_instance_valid(target) and target.alive:
			var offset := target.global_position + Vector3(0, HEIGHT, 0) - global_position
			offset.y *= 0.5
			if offset.length_squared() < HIT_RADIUS * HIT_RADIUS:
				if is_instance_valid(caster):
					Combat.hit(caster, target, skill)
				queue_free()
				return
	if _left <= 0.0:
		queue_free()

# A quarrel is the KayKit arrow; witchfire is a glowing ball. Meshes are shared between bolts.
func _model(look: String) -> Node3D:
	if look == "quarrel":
		var arrow: Node3D = load("res://assets/kaykit/skeletons/weapons/Skeleton_Arrow.gltf").instantiate()
		arrow.rotation_degrees.x = 90.0
		return arrow
	if not _meshes.has(look):
		var sphere := SphereMesh.new()
		sphere.radius = 0.16
		sphere.height = 0.32
		sphere.radial_segments = 12
		sphere.rings = 6
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(skill.params.get("colour", Color("9d6bff"))) * 2.5
		sphere.material = material
		_meshes[look] = sphere
	var ball := MeshInstance3D.new()
	ball.mesh = _meshes[look]
	ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return ball
