class_name ZoneLibrary
# Builds a zone by id. M6 adds the town, the dungeon and the graveyard here.

static func make(id: String) -> Zone:
	var zone: Zone
	match id:
		_:
			zone = TestRoom.new()
	zone.build()
	return zone
