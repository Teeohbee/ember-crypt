class_name BoneBurst
extends Node3D
# A skeleton coming apart: a skull and a handful of bones thrown up and out, bouncing to rest on the
# floor, lying there a moment and sinking away. A few meshes moved by hand, so there's no physics body
# or particle system to pay for, and Feedback keeps a small pool of them to reuse.

const PIECES := 8
const GRAVITY := 18.0
const BOUNCE := 0.35
const FRICTION := 0.55
const LIE_SECONDS := 2.4
const SINK_SECONDS := 0.8
const BONE := Color("d9cfb4")

static var _meshes: Array[Mesh] = []
static var _radii := PackedFloat32Array()

var pieces: Array[MeshInstance3D] = []
var _velocity := PackedVector3Array()
var _spin := PackedVector3Array()
var _floor := 0.0
var _age := 0.0
var _rng := RandomNumberGenerator.new()

var running: bool:
	get: return visible

func _init() -> void:
	name = "BoneBurst"
	process_mode = Node.PROCESS_MODE_PAUSABLE
	top_level = true
	_build_meshes()
	_velocity.resize(PIECES)
	_spin.resize(PIECES)
	for i in PIECES:
		var piece := MeshInstance3D.new()
		piece.mesh = _meshes[i % _meshes.size()]
		piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pieces.append(piece)
		add_child(piece)
	visible = false
	set_physics_process(false)

# Throws the bones from a body standing at `at`, away from `away` (the blow's direction) if given
func burst(at: Vector3, away := Vector3.ZERO, strength := 1.0) -> void:
	_floor = at.y
	_age = 0.0
	away.y = 0.0
	away = away.normalized()
	for i in PIECES:
		var piece := pieces[i]
		piece.position = at + Vector3(_rng.randf_range(-0.3, 0.3), _rng.randf_range(0.6, 1.5), _rng.randf_range(-0.3, 0.3))
		piece.rotation = Vector3(_rng.randf() * TAU, _rng.randf() * TAU, _rng.randf() * TAU)
		var outward := Vector3(_rng.randf_range(-1, 1), 0, _rng.randf_range(-1, 1)).normalized()
		var flung := (outward * _rng.randf_range(1.2, 3.2) + away * 2.5) * strength
		_velocity[i] = flung + Vector3(0, _rng.randf_range(3.5, 6.5), 0)
		_spin[i] = Vector3(_rng.randf_range(-12, 12), _rng.randf_range(-12, 12), _rng.randf_range(-12, 12))
	visible = true
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	_age += delta
	var sinking := maxf(_age - LIE_SECONDS, 0.0)
	if sinking >= SINK_SECONDS:
		visible = false
		set_physics_process(false)
		return
	for i in PIECES:
		var piece := pieces[i]
		var radius := _radii[i % _radii.size()]
		var ground := _floor + radius - sinking / SINK_SECONDS * 0.4
		var velocity := _velocity[i]
		velocity.y -= GRAVITY * delta
		piece.position += velocity * delta
		piece.rotate_object_local(Vector3.RIGHT, _spin[i].x * delta)
		piece.rotate_object_local(Vector3.UP, _spin[i].y * delta)
		if piece.position.y <= ground:
			piece.position.y = ground
			if velocity.y < 0.0:
				velocity.y = -velocity.y * BOUNCE
				if velocity.y < 0.6:
					velocity.y = 0.0
				velocity.x *= FRICTION
				velocity.z *= FRICTION
				_spin[i] *= FRICTION
		_velocity[i] = velocity

static func _build_meshes() -> void:
	if not _meshes.is_empty():
		return
	var material := StandardMaterial3D.new()
	material.albedo_color = BONE
	material.roughness = 0.85
	var skull := SphereMesh.new()
	skull.radius = 0.14
	skull.height = 0.26
	skull.radial_segments = 10
	skull.rings = 6
	var long := CapsuleMesh.new()
	long.radius = 0.035
	long.height = 0.42
	long.radial_segments = 6
	long.rings = 2
	var rib := BoxMesh.new()
	rib.size = Vector3(0.05, 0.05, 0.22)
	var knuckle := BoxMesh.new()
	knuckle.size = Vector3(0.09, 0.07, 0.09)
	for mesh: PrimitiveMesh in [skull, long, rib, long, rib, knuckle, rib, long]:
		mesh.material = material
		_meshes.append(mesh)
	# How far each lies above the floor once it's down
	_radii = PackedFloat32Array([0.13, 0.035, 0.025, 0.035, 0.025, 0.035, 0.025, 0.035])
