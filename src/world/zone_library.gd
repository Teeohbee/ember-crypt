class_name ZoneLibrary
# Builds a zone by id: the town, the graveyard, the crypt (and the M0 test room, for anything else).

# Waypoints in the order the menu lists them: [zone id, name]
const WAYPOINTS := [["town", "Emberfall"], ["graveyard", "The Hollow Graveyard"], ["crypt", "The Ember Crypt"]]

static func make(id: String) -> Zone:
	var zone: Zone
	match id:
		"town":
			zone = Town.new()
		"graveyard":
			zone = Graveyard.new()
		"crypt":
			if Session.dungeon_seed == 0:
				Session.dungeon_seed = randi_range(1, 1 << 30)
			zone = Dungeon.new(Session.dungeon_seed)
		_:
			zone = TestRoom.new()
	zone.build()
	return zone
