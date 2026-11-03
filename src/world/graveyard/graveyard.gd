class_name Graveyard
extends Zone
# The Hollow Graveyard, the outdoor zone between the town and the crypt, built from KayKit's Halloween
# Bits: rows of headstones inside an iron fence, a stone path from the south arch up to the mausoleum
# whose door goes down into the crypt, dead trees inside and autumn pines crowding the fence outside.
# Lantern posts light the path and jack-o'-lanterns grin between the graves; moonlight and thick fog do
# the rest. Nothing solid stands on the path, so the way from the gate to the door is always open.

const ARRIVALS := {"": Vector3(0, 0, 14), "gate": Vector3(0, 0, 14), "waypoint": Vector3(3, 0, 9), "stairs": Vector3(0, 0, -15)}
# The fence: east and west runs at +-WEST_EAST_X, the north run behind the mausoleum, the south with
# the arch in its middle
const WEST_EAST_X := 23.0
const NORTH_Z := -22.0
const GATE_Z := 18.0
# The mausoleum sits in the gap in the north fence, its door facing the path
const CRYPT_Z := -25.0
const CRYPT_DOOR_Z := -20.5
const GRAVE_COLUMNS := [-18.0, -14.0, -10.0, -6.0, 6.0, 10.0, 14.0, 18.0]
const GRAVE_ROWS := [-12.0, -6.0, 0.0, 6.0]
const PACKS := [Vector3(-12, 0, -9), Vector3(12, 0, -3), Vector3(-12, 0, 3), Vector3(13, 0, 9), Vector3(0, 0, -11)]
# Headstones and their footprints (x, z) in metres
const HEADSTONES := {
	"grave_A": Vector2(2.0, 1.0), "grave_B": Vector2(2.0, 1.0), "grave_A_destroyed": Vector2(2.0, 1.0),
	"gravestone": Vector2(1.4, 0.5), "gravemarker_A": Vector2(0.8, 0.4), "gravemarker_B": Vector2(0.8, 0.4),
}
const LANTERN_ROWS := [11.0, -1.0, -14.0]
const JACKS := [Vector3(-4, 0, 8), Vector3(8, 0, -9), Vector3(-15, 0, -4), Vector3(17, 0, 3), Vector3(3.2, 0, -18)]
const PUMPKIN := Color("ff8a2a")

func _init() -> void:
	id = "graveyard"
	display_name = "The Hollow Graveyard"
	music = "graveyard"
	name = "Graveyard"

func environment() -> Environment:
	return Look.night_environment(0.034)

func build() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1031
	add_child(Look.moon(0.65))
	_ground()
	_path(rng)
	_fence(rng)
	_mausoleum()
	for x in GRAVE_COLUMNS:
		for z in GRAVE_ROWS:
			if rng.randf() < 0.82:
				_grave(Vector3(x + rng.randf_range(-0.4, 0.4), 0, z + rng.randf_range(-0.3, 0.3)), rng)
	_trees(rng)
	_lanterns()
	_dressing(rng)
	var monsters := Dungeon.pack_monsters()
	var made := Dungeon.packs()
	for pack: Vector3 in PACKS:
		var point := Dungeon.pack_point(pack, 3, 0, rng, monsters, made)
		point.scatter = 2.0
		add_child(point)
	var checkpoint := Checkpoint.new()
	checkpoint.position = Vector3(0, 0, 0)
	add_child(checkpoint)
	var waypoint := Waypoint.new(id)
	waypoint.position = Vector3(4, 0, 11)
	add_child(waypoint)
	var gate := ZoneExit.new("Back to Emberfall", "town", "gate")
	gate.position = Vector3(0, 0, GATE_Z - 1.5)
	add_child(gate)
	hero_start = ARRIVALS.get(Session.arrival, ARRIVALS[""])

# Bare earth running off into the fog. (The pack's dirt tiles leave a grid of seams from above.)
func _ground() -> void:
	var under := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(110, 100)
	var earth := StandardMaterial3D.new()
	earth.albedo_color = Color("3b342c")
	earth.roughness = 1.0
	plane.material = earth
	under.mesh = plane
	under.position = Vector3(0, -0.02, -4)
	add_child(under)

# Flagstones from the arch to the mausoleum door, laid a little crooked
func _path(rng: RandomNumberGenerator) -> void:
	var z := GATE_Z + 1.0
	while z > CRYPT_DOOR_Z:
		for x in [-0.95, 0.95]:
			var stone: String = ["path_A", "path_B", "path_C", "path_D"][rng.randi_range(0, 3)]
			HalloweenKit.place(self, stone, Vector3(x + rng.randf_range(-0.1, 0.1), 0, z), rng.randi_range(0, 3) * 90.0)
		z -= 1.9

# Iron fence all round, broken here and there, with stone pillars at the corners and an arch for the
# way in at the south. The mausoleum fills the gap in the north run.
func _fence(rng: RandomNumberGenerator) -> void:
	for side in [-1.0, 1.0]:
		var x: float = side * WEST_EAST_X
		var z := NORTH_Z + 2.0
		while z < GATE_Z:
			_fence_piece(Vector3(x, 0, z), 90.0, rng)
			z += 4.0
		for run_z in [NORTH_Z, GATE_Z]:
			var along := 5.0
			while along < WEST_EAST_X:
				_fence_piece(Vector3(side * along, 0, run_z), 0.0, rng)
				along += 4.0
			HalloweenKit.place(self, "pillar", Vector3(x, 0, run_z))
		var length := GATE_Z - NORTH_Z
		CryptKit.blocker(self, Vector3(x, 1.5, NORTH_Z + length * 0.5), Vector3(1, 3, length))
		var span := WEST_EAST_X - 3.0
		CryptKit.blocker(self, Vector3(side * (3.0 + span * 0.5), 1.5, NORTH_Z), Vector3(span, 3, 1))
		CryptKit.blocker(self, Vector3(side * (3.0 + span * 0.5), 1.5, GATE_Z), Vector3(span, 3, 1))
		HalloweenKit.place(self, "fence_pillar", Vector3(side * 2.6, 0, GATE_Z))
	HalloweenKit.place(self, "arch", Vector3(0, 0, GATE_Z))
	# Past the arch is the road back to town, which the gate's exit stands for; nobody walks out that way
	CryptKit.blocker(self, Vector3(0, 1.5, GATE_Z + 1.5), Vector3(4, 3, 1))

func _fence_piece(at: Vector3, yaw: float, rng: RandomNumberGenerator) -> void:
	HalloweenKit.place(self, "fence_broken" if rng.randf() < 0.18 else "fence", at, yaw)

# The mausoleum, lit by a shaft of moonlight, with candles at its door
func _mausoleum() -> void:
	HalloweenKit.place(self, "crypt", Vector3(0, 0, CRYPT_Z))
	CryptKit.blocker(self, Vector3(0, 2, CRYPT_Z), Vector3(6, 4, 8))
	for side in [-1.0, 1.0]:
		HalloweenKit.place(self, "candle_triple", Vector3(side * 1.9, 0, CRYPT_DOOR_Z + 0.4))
		HalloweenKit.solid(self, "shrine_candles", Vector3(side * 4.4, 0, CRYPT_DOOR_Z + 1.0), Vector2(1.1, 1.1))
	var shaft := Look.spotlight(Look.MOONLIGHT, 7.0, 26.0)
	shaft.position = Vector3(0, 9, CRYPT_DOOR_Z + 6)
	shaft.rotation_degrees.x = -70
	add_child(shaft)
	var candles := OmniLight3D.new()
	candles.light_color = Look.CANDLE
	candles.light_energy = 1.4
	candles.omni_range = 5.0
	candles.position = Vector3(0, 1.4, CRYPT_DOOR_Z + 1.5)
	candles.set_script(Flicker)
	add_child(candles)
	var stairs := ZoneExit.new("Descend into the crypt", "crypt", "stairs")
	stairs.position = Vector3(0, 0, CRYPT_DOOR_Z + 1.5)
	add_child(stairs)

# A headstone, most often a proper grave, leaning a little; now and then a candle someone left
func _grave(at: Vector3, rng: RandomNumberGenerator) -> void:
	var names := HEADSTONES.keys()
	var piece: String = names[rng.randi_range(0, names.size() - 1)]
	var head := at + Vector3(0, 0, -1.0)
	var node := HalloweenKit.solid(self, piece, head, HEADSTONES[piece])
	node.rotation_degrees.y = rng.randf_range(-8, 8)
	node.rotation_degrees.z = rng.randf_range(-5, 5)
	if rng.randf() < 0.18:
		HalloweenKit.place(self, ["candle", "candle_melted", "candle_thin"][rng.randi_range(0, 2)], at + Vector3(1.1, 0, -0.4))

# Dead trees in among the graves, and a wall of autumn pines outside the fence so the graveyard has
# an edge against the sky
func _trees(rng: RandomNumberGenerator) -> void:
	for at in [Vector3(-9, 0, -16), Vector3(9.5, 0, 13), Vector3(-17, 0, 10), Vector3(16, 0, -16), Vector3(-20, 0, -8)]:
		var piece: String = ["tree_dead_large", "tree_dead_large_decorated", "tree_dead_medium"][rng.randi_range(0, 2)]
		HalloweenKit.solid(self, piece, at, Vector2(0.8, 0.8), rng.randf_range(0, 360))
	var pines := ["tree_pine_orange_large", "tree_pine_orange_medium", "tree_pine_yellow_large", "tree_pine_yellow_medium", "tree_dead_large"]
	for side in [-1.0, 1.0]:
		var z := NORTH_Z - 6.0
		while z < GATE_Z + 6.0:
			HalloweenKit.place(self, pines[rng.randi_range(0, pines.size() - 1)], Vector3(side * rng.randf_range(26.5, 30.0), 0, z), rng.randf_range(0, 360))
			z += rng.randf_range(4.5, 6.5)
	var x := -WEST_EAST_X
	while x < WEST_EAST_X:
		if absf(x) > 5.0:
			HalloweenKit.place(self, pines[rng.randi_range(0, pines.size() - 1)], Vector3(x, 0, NORTH_Z - rng.randf_range(4.0, 7.0)), rng.randf_range(0, 360))
		x += rng.randf_range(4.5, 6.5)

# Lantern posts in pairs along the path, each hanging its lantern over the stones
func _lanterns() -> void:
	for z: float in LANTERN_ROWS:
		for side in [-1.0, 1.0]:
			var at := Vector3(side * 2.6, 0, z)
			HalloweenKit.place(self, "post_lantern", at, -90.0 * side)
			CryptKit.blocker(self, at + Vector3(0, 1.0, 0), Vector3(0.5, 2.0, 0.5))
			var light := OmniLight3D.new()
			light.light_color = Look.CANDLE
			light.light_energy = 1.8
			light.omni_range = 7.0
			light.omni_attenuation = 1.8
			light.light_volumetric_fog_energy = 1.2
			light.position = at + Vector3(-side * 1.1, 2.5, 0)
			light.set_script(Flicker)
			add_child(light)

# Jack-o'-lanterns with a little orange glow, pumpkins to smash, bones, coffins and the odd bench
func _dressing(rng: RandomNumberGenerator) -> void:
	for at: Vector3 in JACKS:
		HalloweenKit.solid(self, ["pumpkin_orange_jackolantern", "pumpkin_yellow_jackolantern"][rng.randi_range(0, 1)], at, Vector2(1.2, 1.2), rng.randf_range(150, 210))
		var glow := OmniLight3D.new()
		glow.light_color = PUMPKIN
		glow.light_energy = 1.2
		glow.omni_range = 3.5
		glow.position = at + Vector3(0, 0.7, 0.6)
		glow.set_script(Flicker)
		add_child(glow)
	for i in 22:
		var at := Vector3(rng.randf_range(-21, 21), 0, rng.randf_range(-19, 16))
		if absf(at.x) < 3.5:
			continue
		var piece: String = ["pumpkin_orange", "pumpkin_orange_small", "pumpkin_yellow_small", "pumpkin_yellow", "skull", "bone_A", "bone_C", "ribcage"][rng.randi_range(0, 7)]
		if Breakable.is_breakable(piece):
			var pumpkin := Breakable.make(piece, rng.randi_range(0, 3) * 90.0)
			pumpkin.position = at
			add_child(pumpkin)
		else:
			HalloweenKit.place(self, piece, at, rng.randf_range(0, 360))
	HalloweenKit.place(self, "floor_dirt_grave", Vector3(-16, 0, -17))
	HalloweenKit.solid(self, "coffin", Vector3(-12.5, 0, -17), Vector2(2.0, 3.0), 90.0)
	HalloweenKit.solid(self, "coffin_decorated", Vector3(15, 0, 14.5), Vector2(2.0, 3.0), 90.0)
	HalloweenKit.solid(self, "bench_decorated", Vector3(-6, 0, 13), Vector2(2.0, 1.0))
	HalloweenKit.solid(self, "plaque_candles", Vector3(6, 0, -16), Vector2(2.0, 2.0))
	CryptKit.blocker(self, Vector3(-16, 1.0, -17), Vector3(4, 2, 4))
