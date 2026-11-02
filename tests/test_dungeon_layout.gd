extends GdUnitTestSuite
# The dungeon generator: seeded, connected, and the boss at the far end.

func _chunk(id: StringName, kinds: PackedStringArray) -> RoomChunk:
	var chunk := RoomChunk.new()
	chunk.id = id
	chunk.kinds = kinds
	return chunk

func _chunks() -> Array[RoomChunk]:
	return [_chunk(&"entry", ["start"]), _chunk(&"hall", ["fight"]), _chunk(&"ossuary", ["fight"]),
		_chunk(&"throne", ["boss"])]

func _describe(layout: DungeonLayout) -> Array:
	var described := []
	for cell: Vector2i in layout.rooms:
		var room: DungeonLayout.Room = layout.rooms[cell]
		described.append([cell, room.doors, room.kind, room.chunk.id if room.chunk else &""])
	return described

func test_the_same_seed_makes_the_same_dungeon() -> void:
	var first := DungeonLayout.generate(42, 9, _chunks())
	var second := DungeonLayout.generate(42, 9, _chunks())
	assert_array(_describe(first)).is_equal(_describe(second))

func test_different_seeds_make_different_dungeons() -> void:
	var shapes := {}
	for seed_value in 8:
		shapes[str(_describe(DungeonLayout.generate(seed_value, 9, _chunks())))] = true
	assert_int(shapes.size()).is_greater(4)

func test_it_makes_as_many_rooms_as_asked() -> void:
	for seed_value in 20:
		assert_int(DungeonLayout.generate(seed_value, 10, _chunks()).rooms.size()).is_equal(10)

func test_every_room_can_be_reached_from_the_start() -> void:
	for seed_value in 20:
		var layout := DungeonLayout.generate(seed_value, 10, _chunks())
		var seen := {layout.start.cell: true}
		var queue: Array[Vector2i] = [layout.start.cell]
		while not queue.is_empty():
			var room: DungeonLayout.Room = layout.rooms[queue.pop_front()]
			for direction: int in DungeonLayout.DIRECTIONS:
				var next: Vector2i = room.cell + DungeonLayout.DIRECTIONS[direction]
				if room.has_door(direction) and not seen.has(next):
					seen[next] = true
					queue.append(next)
		assert_int(seen.size()).is_equal(layout.rooms.size())

func test_doors_always_open_both_ways_onto_a_room() -> void:
	for seed_value in 20:
		var layout := DungeonLayout.generate(seed_value, 10, _chunks())
		for cell: Vector2i in layout.rooms:
			var room: DungeonLayout.Room = layout.rooms[cell]
			for direction: int in DungeonLayout.DIRECTIONS:
				if room.has_door(direction):
					var next: DungeonLayout.Room = layout.rooms.get(cell + DungeonLayout.DIRECTIONS[direction])
					assert_object(next).is_not_null()
					assert_bool(next.has_door(DungeonLayout.OPPOSITE[direction])).is_true()

func test_the_boss_is_in_a_dead_end_furthest_from_the_start() -> void:
	for seed_value in 20:
		var layout := DungeonLayout.generate(seed_value, 10, _chunks())
		assert_str(layout.boss.kind).is_equal("boss")
		assert_int(layout.boss.door_count()).is_equal(1)
		for room: DungeonLayout.Room in layout.rooms.values():
			assert_int(room.depth).is_less_equal(layout.boss.depth)

func test_a_checkpoint_waits_halfway_along_the_way_to_the_boss() -> void:
	var layout := DungeonLayout.generate(7, 10, _chunks())
	var checkpoints := layout.rooms.values().filter(func(room: DungeonLayout.Room) -> bool: return room.kind == &"checkpoint")
	assert_int(checkpoints.size()).is_equal(1)
	var checkpoint: DungeonLayout.Room = checkpoints[0]
	assert_int(checkpoint.depth).is_equal(layout.boss.depth / 2)
	# On the way: following parents back from the boss passes through it
	var cell := layout.boss.cell
	var passed := false
	while cell != layout.start.cell:
		cell = layout.rooms[cell].parent
		passed = passed or cell == checkpoint.cell
	assert_bool(passed).is_true()

func test_rooms_get_a_chunk_made_for_their_kind() -> void:
	var layout := DungeonLayout.generate(3, 10, _chunks())
	assert_str(layout.start.kind).is_equal("start")
	assert_str(layout.start.chunk.id).is_equal("entry")
	assert_str(layout.boss.chunk.id).is_equal("throne")
	for room: DungeonLayout.Room in layout.rooms.values():
		if room.kind in [&"fight", &"checkpoint"]:
			assert_array([&"hall", &"ossuary"]).contains([room.chunk.id])

func test_the_entrance_never_opens_north_where_the_stairs_are() -> void:
	for seed_value in 30:
		assert_bool(DungeonLayout.generate(seed_value, 10, _chunks()).start.has_door(DungeonLayout.NORTH)).is_false()
