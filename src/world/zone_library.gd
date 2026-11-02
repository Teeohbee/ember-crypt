class_name ZoneLibrary
# Builds a zone by id. M6 adds the town, the dungeon and the graveyard here.

static func make(id: String) -> Zone:
	var zone: Zone
	match id:
		"crypt":
			if Session.dungeon_seed == 0:
				Session.dungeon_seed = randi_range(1, 1 << 30)
			zone = Dungeon.new(Session.dungeon_seed)
		_:
			zone = TestRoom.new()
	zone.build()
	return zone
