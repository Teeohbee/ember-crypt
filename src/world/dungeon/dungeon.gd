class_name Dungeon
extends Zone
# The Ember Crypt: a fresh layout of hand-made rooms from a seed. Session keeps the seed, so going back
# in by waypoint finds the same crypt. Packs get bigger and more often led by elites the deeper they
# are; a checkpoint waits halfway, and the boss in the furthest room.

const CHUNKS_DIR := "res://src/world/dungeon/chunks/"
const ROOMS := 9
# Whichever of these exist make up the packs (M3 adds the last three)
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
	for room: DungeonLayout.Room in layout.rooms.values():
		RoomBuilder.build(self, room, seed_value)
		_fill(room, monsters)
	hero_start = RoomBuilder.centre(layout.start.cell) + Vector3(0, 0, 3)

static func chunks() -> Array[RoomChunk]:
	var found: Array[RoomChunk] = []
	for file in ResourceLoader.list_directory(CHUNKS_DIR):
		if file.ends_with(".tres"):
			found.append(load(CHUNKS_DIR + file))
	return found

static func pack_monsters() -> Array[StringName]:
	var found: Array[StringName] = []
	for monster in PACK_MONSTERS:
		if ResourceLoader.exists(MonsterLibrary.DEFS_DIR + String(monster) + ".tres"):
			found.append(monster)
	return found

func _fill(room: DungeonLayout.Room, monsters: Array[StringName]) -> void:
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
		var point := SpawnPoint.new()
		point.monsters = monsters.duplicate()
		point.count = room.chunk.pack_size + room.depth / 3
		point.elite_chance = minf(0.08 + 0.04 * room.depth, 0.5)
		point.position = at + pack
		add_child(point)

func _add_checkpoint(at: Vector3) -> void:
	var checkpoint := Checkpoint.new()
	checkpoint.position = at
	add_child(checkpoint)

# The stairs back up and the waypoint, in the entrance room (filled in by the waypoint work)
func _furnish_start(_at: Vector3) -> void:
	pass

# The boss and its arena (filled in by the boss work)
func _furnish_boss(_at: Vector3) -> void:
	pass
