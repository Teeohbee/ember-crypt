extends GdUnitTestSuite
# The hand-made rooms and the crypt built from them, checked without running a scene.

const LANE := 2.5

func test_every_chunk_uses_real_pieces_and_keeps_the_doorways_clear() -> void:
	var chunks := Dungeon.chunks()
	assert_int(chunks.size()).is_greater_equal(5)
	for chunk in chunks:
		for prop: Array in chunk.props:
			var piece: String = prop[0]
			assert_object(CryptKit.scene(piece)).override_failure_message("%s: no piece %s" % [chunk.id, piece]).is_not_null()
			var at: Vector3 = prop[1]
			if piece != "stairs":
				assert_bool(_in_a_doorway(at)).override_failure_message("%s: %s blocks a doorway" % [chunk.id, piece]).is_false()
		for point in Array(chunk.packs) + Array(chunk.fires):
			assert_bool(_in_a_doorway(point)).is_false()

func test_there_is_a_chunk_for_every_kind_of_room() -> void:
	var kinds := {}
	for chunk in Dungeon.chunks():
		for kind in chunk.kinds:
			kinds[kind] = true
	assert_array(kinds.keys()).contains(["start", "fight", "boss"])

func test_the_crypt_has_packs_a_checkpoint_and_walls_to_bump_into() -> void:
	var dungeon: Dungeon = auto_free(Dungeon.new(5))
	dungeon.build()
	var packs := 0
	for room: DungeonLayout.Room in dungeon.layout.rooms.values():
		if room.kind in [&"fight", &"checkpoint"]:
			packs += room.chunk.packs.size()
	assert_int(dungeon.spawn_points().size()).is_equal(packs + 1)
	assert_int(dungeon.find_children("*", "BossSpawn", true, false).size()).is_equal(1)
	assert_int(dungeon.find_children("*", "Checkpoint", true, false).size()).is_equal(2)
	assert_int(dungeon.find_children("*", "StaticBody3D", true, false).size()).is_greater(100)
	assert_vector(dungeon.hero_start).is_equal(RoomBuilder.centre(dungeon.layout.start.cell) + Vector3(0, 0, 3))

func test_the_crypt_remembers_its_seed_between_visits() -> void:
	var before := Session.dungeon_seed
	Session.dungeon_seed = 0
	var first: Dungeon = auto_free(ZoneLibrary.make("crypt"))
	var second: Dungeon = auto_free(ZoneLibrary.make("crypt"))
	assert_int(Session.dungeon_seed).is_not_equal(0)
	assert_int(first.seed_value).is_equal(second.seed_value)
	Session.dungeon_seed = before

func _in_a_doorway(at: Vector3) -> bool:
	return (absf(at.x) < LANE and absf(at.z) > 6.0) or (absf(at.z) < LANE and absf(at.x) > 6.0)
