class_name Dungeon
extends Zone
# The Ember Crypt: a fresh layout of hand-made rooms from a seed. Session keeps the seed, so going back
# in by waypoint finds the same crypt. Packs get bigger and more often led by elites the deeper they
# are; a checkpoint waits halfway, and the boss in the furthest room.

const CHUNKS_DIR := "res://src/world/dungeon/chunks/"
const PACKS_DIR := "res://src/monsters/packs/"
# Chance a pack spot gets one of M3's made-up packs rather than a plain crowd
const MADE_PACK_CHANCE := 0.55
const ROOMS := 9
# Whichever of these exist make up the plain crowds
const PACK_MONSTERS: Array[StringName] = [&"skeleton_minion", &"skeleton_warrior", &"skeleton_rogue", &"skeleton_mage"]

var seed_value := 1
var layout: DungeonLayout

func _init(seed_number := 1) -> void:
	seed_value = seed_number
	id = "crypt"
	display_name = "The Ember Crypt"
	name = "Dungeon"

func build() -> void:
	layout = DungeonLayout.generate(seed_value, ROOMS, chunks())
	var monsters := pack_monsters()
	var made := packs()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for room: DungeonLayout.Room in layout.rooms.values():
		RoomBuilder.build(self, room, seed_value)
		_fill(room, monsters, made, rng)
	hero_start = RoomBuilder.centre(layout.start.cell) + Vector3(0, 0, 3)

static func chunks() -> Array[RoomChunk]:
	var found: Array[RoomChunk] = []
	for file in ResourceLoader.list_directory(CHUNKS_DIR):
		if file.ends_with(".tres"):
			found.append(load(CHUNKS_DIR + file))
	return found

static func packs() -> Array[PackDef]:
	var found: Array[PackDef] = []
	if DirAccess.dir_exists_absolute(PACKS_DIR):
		for file in ResourceLoader.list_directory(PACKS_DIR):
			if file.ends_with(".tres"):
				found.append(load(PACKS_DIR + file))
	return found

# A spawn point for a pack at, seeded so the same crypt has the same packs. Deeper is bigger, and more
# often led by an elite.
static func pack_point(at: Vector3, size: int, depth: int, rng: RandomNumberGenerator, monsters: Array[StringName], made: Array[PackDef]) -> SpawnPoint:
	var point := SpawnPoint.new()
	point.monsters = monsters.duplicate()
	point.count = size + depth / 3
	if not made.is_empty() and rng.randf() < MADE_PACK_CHANCE:
		point.pack = made[rng.randi_range(0, made.size() - 1)]
	point.elite_chance = minf(0.08 + 0.04 * depth, 0.5)
	point.rng.seed = rng.randi()
	point.position = at
	return point

static func pack_monsters() -> Array[StringName]:
	var found: Array[StringName] = []
	for monster in PACK_MONSTERS:
		if ResourceLoader.exists(MonsterLibrary.DEFS_DIR + String(monster) + ".tres"):
			found.append(monster)
	return found

func _fill(room: DungeonLayout.Room, monsters: Array[StringName], made: Array[PackDef], rng: RandomNumberGenerator) -> void:
	var at := RoomBuilder.centre(room.cell)
	match room.kind:
		&"start":
			_add_checkpoint(at)
			_furnish_start(at)
		&"checkpoint":
			_add_checkpoint(at)
		&"boss":
			_furnish_boss(at)
	if room.chunk == null or monsters.is_empty():
		return
	for pack in room.chunk.packs:
		add_child(pack_point(at + pack, room.chunk.pack_size, room.depth, rng, monsters, made))

func _add_checkpoint(at: Vector3) -> void:
	var checkpoint := Checkpoint.new()
	checkpoint.position = at
	add_child(checkpoint)

# The stairs back up (the entry chunk puts them against the north wall) and the waypoint
func _furnish_start(at: Vector3) -> void:
	CryptKit.blocker(self, at + Vector3(0, 1.0, -7.5), Vector3(5.0, 2.0, 4.0))
	var stairs := ZoneExit.new("Climb to the graveyard", "graveyard", "stairs")
	stairs.position = at + Vector3(0, 0, -4.8)
	add_child(stairs)
	var waypoint := Waypoint.new(id)
	waypoint.position = at + Vector3(6, 0, 5)
	add_child(waypoint)

# The boss waits in the middle of its throne room
func _furnish_boss(at: Vector3) -> void:
	var boss := BossSpawn.new()
	boss.position = at
	add_child(boss)
