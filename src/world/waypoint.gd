class_name Waypoint
extends Node3D
# A ring of cold fire on the floor. Walking over it the first time adds its zone to the waypoints you
# know; using it opens the list of known waypoints and takes you to any of them.

const RADIUS := 1.25
const GLOW := Color(0.45, 0.78, 1.0)

var zone_id := ""
var interactable := Interactable.new("Waypoint", 2.6)
var light := OmniLight3D.new()

func _init(for_zone := "") -> void:
	zone_id = for_zone
	name = "Waypoint"
	add_child(interactable)
	add_child(light)

func _ready() -> void:
	_build_look()
	interactable.used.connect(open_menu)
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 1
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = RADIUS + 0.5
	shape.shape = sphere
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(func(body: Node3D) -> void:
		if body is Hero:
			discover())

# True the first time; the ring flares and chimes
func discover() -> bool:
	if zone_id == "" or zone_id in Session.waypoints:
		return false
	Session.waypoints.append(zone_id)
	Sound.play("waypoint")
	var tween := create_tween()
	tween.tween_property(light, "light_energy", 6.0, 0.15)
	tween.tween_property(light, "light_energy", 1.8, 1.2)
	return true

func open_menu(hero: Hero) -> void:
	discover()
	WorldScreen.show_screen(WaypointMenu.new(zone_id), hero)

func _build_look() -> void:
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = GLOW
	glow.emission_enabled = true
	glow.emission = GLOW
	glow.emission_energy_multiplier = 3.0
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = RADIUS - 0.12
	torus.outer_radius = RADIUS
	torus.rings = 48
	torus.ring_segments = 6
	torus.material = glow
	ring.mesh = torus
	ring.position.y = 0.08
	add_child(ring)
	var pool := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = RADIUS - 0.1
	disc.bottom_radius = RADIUS - 0.1
	disc.height = 0.01
	var wash := StandardMaterial3D.new()
	wash.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wash.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	wash.albedo_color = Color(GLOW, 0.25)
	disc.material = wash
	pool.mesh = disc
	pool.position.y = 0.06
	add_child(pool)
	light.light_color = GLOW
	light.light_energy = 1.8
	light.omni_range = 6.0
	light.position.y = 1.2
	light.light_volumetric_fog_energy = 2.0
	add_child(_motes())

# A few sparks drifting up out of the ring
func _motes() -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.amount = 14
	particles.lifetime = 2.2
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	process.emission_ring_axis = Vector3.UP
	process.emission_ring_radius = RADIUS - 0.06
	process.emission_ring_inner_radius = RADIUS - 0.2
	process.emission_ring_height = 0.05
	process.direction = Vector3.UP
	process.spread = 6.0
	process.initial_velocity_min = 0.4
	process.initial_velocity_max = 0.8
	process.gravity = Vector3.ZERO
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.9))
	fade.set_color(1, Color(1, 1, 1, 0.0))
	var fade_texture := GradientTexture1D.new()
	fade_texture.gradient = fade
	process.color_ramp = fade_texture
	particles.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2(0.08, 0.08)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color(GLOW * 2.5, 1.0)
	quad.material = material
	particles.draw_pass_1 = quad
	particles.position.y = 0.1
	return particles
