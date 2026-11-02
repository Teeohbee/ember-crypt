class_name Graveyard
extends Zone
# The Hollow Graveyard, the outdoor zone between the town and the crypt: rows of dug graves and
# leaning headstones inside an iron-and-stone railing, a paved path up the middle to the mausoleum
# whose door goes down into the crypt. Moonlight and thick fog do most of the work.
#
# The plan wanted KayKit's Halloween Bits here; that pack isn't in the repo, so it's built from the
# dungeon kit: headstones are squashed wall end caps, graves are the dirt tiles (which read as holes
# from above), the railing is the balustrade. Swap the pieces in _grave and _fence when the pack lands.

const ARRIVALS := {"": Vector3(0, 0, 14), "gate": Vector3(0, 0, 14), "waypoint": Vector3(3, 0, 9), "stairs": Vector3(0, 0, -15)}
const HALF_X := 5
const NORTH := -5
const SOUTH := 4
const GRAVE_COLUMNS := [-18.0, -14.0, -10.0, -6.0, 6.0, 10.0, 14.0, 18.0]
const GRAVE_ROWS := [-12.0, -6.0, 0.0, 6.0]
const PACKS := [Vector3(-12, 0, -9), Vector3(12, 0, -3), Vector3(-12, 0, 3), Vector3(13, 0, 9), Vector3(0, 0, -11)]
const HEADSTONE_SCALE := Vector3(0.7, 0.24, 0.32)

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
	for z in range(NORTH, SOUTH + 1):
		CryptKit.place(self, "floor_tile_large" if rng.randf() > 0.3 else "floor_tile_large_rocks", Vector3(0, 0, z * CryptKit.CELL), rng.randi_range(0, 3) * 90.0)
	_fence(rng)
	_mausoleum()
	for x in GRAVE_COLUMNS:
		for z in GRAVE_ROWS:
			if rng.randf() < 0.82:
				_grave(Vector3(x + rng.randf_range(-0.4, 0.4), 0, z + rng.randf_range(-0.3, 0.3)), rng)
	for at in [Vector3(-5, 0, 10), Vector3(5, 0, -16)]:
		RoomBuilder.brazier(self, at)
	CryptKit.place(self, "rubble_half", Vector3(-19, 0, 12), 40)
	CryptKit.place(self, "rubble_half", Vector3(18, 0, -17), 200)
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
	gate.position = Vector3(0, 0, 16.5)
	add_child(gate)
	hero_start = ARRIVALS.get(Session.arrival, ARRIVALS[""])

# Bare earth under everything, with the odd patch of turned dirt
func _ground() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(64, 56)
	var earth := StandardMaterial3D.new()
	earth.albedo_color = Color("1d1b16")
	earth.roughness = 1.0
	plane.material = earth
	ground.mesh = plane
	ground.position = Vector3(0, -0.06, -2)
	add_child(ground)

# Balustrade round three sides with a gap for the path at the south, a high wall behind the mausoleum
func _fence(rng: RandomNumberGenerator) -> void:
	var west := -HALF_X
	var east := HALF_X + 1
	var south := SOUTH + 1
	RoomBuilder.wall_run(self, Vector2i(west, NORTH), Vector2i(east, NORTH), HALF_X, false, rng)
	for side in [[Vector2i(west, NORTH), Vector2i(west, south)], [Vector2i(east, NORTH), Vector2i(east, south)]]:
		CryptKit.wall(self, side[0], side[1], func(i: int) -> String: return "barrier_column" if i % 2 == 0 else "barrier")
		var length := (south - NORTH) * CryptKit.CELL
		var x: float = (side[0].x - 0.5) * CryptKit.CELL
		CryptKit.blocker(self, Vector3(x, 1.5, (NORTH - 0.5) * CryptKit.CELL + length * 0.5), Vector3(1, 3, length))
	var z := (south - 0.5) * CryptKit.CELL
	for i in east - west:
		if west + i != 0:
			CryptKit.place(self, "barrier_column" if i % 2 == 0 else "barrier", Vector3((west + i) * CryptKit.CELL, 0, z))
	var span := (HALF_X + 0.5) * CryptKit.CELL - CryptKit.CELL * 0.5
	for side in [-1.0, 1.0]:
		CryptKit.blocker(self, Vector3(side * (CryptKit.CELL * 0.5 + span * 0.5), 1.5, z), Vector3(span, 3, 1))
	CryptKit.blocker(self, Vector3(0, 1.5, z + 1.5), Vector3(CryptKit.CELL, 3, 1))

# The mausoleum door is the doorway in the north wall, pillared and lit by a shaft of moonlight
func _mausoleum() -> void:
	var door_z := (NORTH - 0.5) * CryptKit.CELL
	var door_x := 0.0
	for side in [-1.0, 1.0]:
		RoomBuilder.prop_at(self, "pillar_decorated", Vector3(door_x + side * 3.2, 0, door_z + 1.2))
		CryptKit.place(self, "candle_triple", Vector3(door_x + side * 1.6, 0, door_z + 1.4))
	CryptKit.blocker(self, Vector3(door_x, 2, door_z - 1.5), Vector3(4, 4, 1))
	var shaft := Look.spotlight(Look.MOONLIGHT, 7.0, 26.0)
	shaft.position = Vector3(door_x, 9, door_z + 4)
	shaft.rotation_degrees.x = -70
	add_child(shaft)
	var candles := OmniLight3D.new()
	candles.light_color = Look.CANDLE
	candles.light_energy = 1.4
	candles.omni_range = 5.0
	candles.position = Vector3(door_x, 1.4, door_z + 2)
	candles.set_script(Flicker)
	add_child(candles)
	var stairs := ZoneExit.new("Descend into the crypt", "crypt", "stairs")
	stairs.position = Vector3(door_x, 0, door_z + 2)
	add_child(stairs)

# A dug grave with its headstone, now and then a post instead, now and then a candle someone left
func _grave(at: Vector3, rng: RandomNumberGenerator) -> void:
	CryptKit.place(self, ["floor_dirt_small_A", "floor_dirt_small_B", "floor_dirt_small_C"][rng.randi_range(0, 2)], at)
	var head := at + Vector3(0, 0, -1.3)
	var lean := rng.randf_range(-12, 12)
	if rng.randf() < 0.75:
		var stone := CryptKit.place(self, "wall_endcap", head, lean)
		stone.scale = HEADSTONE_SCALE
		stone.rotation_degrees.x = rng.randf_range(-8, 6)
	else:
		CryptKit.place(self, "column", head, lean)
	CryptKit.blocker(self, head + Vector3(0, 0.5, 0), Vector3(0.9, 1, 0.5))
	if rng.randf() < 0.18:
		CryptKit.place(self, "candle_lit", at + Vector3(0.7, 0, -0.9))
