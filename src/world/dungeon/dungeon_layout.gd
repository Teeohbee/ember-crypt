class_name DungeonLayout
extends RefCounted
# The shape of a generated dungeon before any of it is built: rooms on a grid, which neighbours each
# opens on to, and what each room is for. Pure and seeded, so a seed is always the same crypt and the
# tests can poke it. Rooms grow as a tree from the entrance, so there's one way to every room, and the
# boss waits in the room furthest in - always a dead end, so it can't be walked past. The entrance
# never opens north: that wall holds the stairs back up.

const NORTH := 1
const EAST := 2
const SOUTH := 4
const WEST := 8
const DIRECTIONS := {NORTH: Vector2i(0, -1), EAST: Vector2i(1, 0), SOUTH: Vector2i(0, 1), WEST: Vector2i(-1, 0)}
const OPPOSITE := {NORTH: SOUTH, EAST: WEST, SOUTH: NORTH, WEST: EAST}
# New rooms grow off one of the last few made, so the crypt runs in long passages rather than a blob
const GROW_FROM_NEWEST := 3

class Room:
	var cell: Vector2i
	# The room it was grown from (its own cell for the start)
	var parent: Vector2i
	# NORTH | EAST | ... for each side with a doorway
	var doors := 0
	# Rooms away from the start
	var depth := 0
	# start, fight, checkpoint, boss
	var kind := &"fight"
	var chunk: RoomChunk

	func has_door(direction: int) -> bool:
		return doors & direction != 0

	func door_count() -> int:
		var count := 0
		for direction: int in DIRECTIONS:
			if has_door(direction):
				count += 1
		return count

var seed_value := 0
# Vector2i -> Room, in the order they were made
var rooms := {}
var start: Room
var boss: Room

static func generate(seed_number: int, room_count: int, chunks: Array[RoomChunk] = []) -> DungeonLayout:
	var layout := DungeonLayout.new()
	layout.seed_value = seed_number
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_number
	layout.start = layout._add(Vector2i.ZERO, null, 0)
	var order: Array[Room] = [layout.start]
	var attempts := 0
	while layout.rooms.size() < room_count and attempts < room_count * 200:
		attempts += 1
		var from: Room = order[order.size() - 1 - rng.randi_range(0, mini(GROW_FROM_NEWEST, order.size()) - 1)]
		var direction: int = DIRECTIONS.keys()[rng.randi_range(0, 3)]
		var cell: Vector2i = from.cell + DIRECTIONS[direction]
		if layout.rooms.has(cell) or (from == layout.start and direction == NORTH):
			continue
		order.append(layout._add(cell, from, direction))
	layout._assign_kinds()
	for room: Room in layout.rooms.values():
		room.chunk = pick_chunk(room.kind, chunks, rng)
	return layout

# A weighted pick among the chunks made for kind. Checkpoint rooms are fight rooms with a checkpoint.
static func pick_chunk(kind: StringName, chunks: Array[RoomChunk], rng: RandomNumberGenerator) -> RoomChunk:
	var wanted := "fight" if kind == &"checkpoint" else String(kind)
	var fitting := chunks.filter(func(chunk: RoomChunk) -> bool: return wanted in chunk.kinds)
	if fitting.is_empty():
		return null
	var total := 0
	for chunk: RoomChunk in fitting:
		total += chunk.weight
	var roll := rng.randi_range(1, maxi(total, 1))
	for chunk: RoomChunk in fitting:
		roll -= chunk.weight
		if roll <= 0:
			return chunk
	return fitting.back()

func _add(cell: Vector2i, from: Room, direction: int) -> Room:
	var room := Room.new()
	room.cell = cell
	room.parent = cell
	if from:
		room.parent = from.cell
		room.depth = from.depth + 1
		from.doors |= direction
		room.doors |= OPPOSITE[direction]
	rooms[cell] = room
	return room

func _assign_kinds() -> void:
	start.kind = &"start"
	boss = start
	for room: Room in rooms.values():
		if room.depth > boss.depth:
			boss = room
	if boss == start:
		return
	boss.kind = &"boss"
	var halfway := boss.depth / 2
	var room := boss
	while room.depth > halfway:
		room = rooms[room.parent]
	if room != start:
		room.kind = &"checkpoint"
