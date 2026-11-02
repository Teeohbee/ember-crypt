extends GdUnitTestSuite
# The hand-built zones, built off-screen: what each has in it and where heroes come in.

var _arrival := ""

func before_test() -> void:
	_arrival = Session.arrival

func after_test() -> void:
	Session.arrival = _arrival

func _build(zone_id: String, arrival := "") -> Zone:
	Session.arrival = arrival
	return auto_free(ZoneLibrary.make(zone_id))

func _named(zone: Zone, type: String) -> Array:
	return zone.find_children("*", type, true, false)

func test_the_town_has_a_stash_a_merchant_a_waypoint_and_a_gate() -> void:
	var town: Town = _build("town")
	assert_str(town.id).is_equal("town")
	assert_object(town.stash).is_not_null()
	assert_object(town.merchant).is_not_null()
	assert_int(_named(town, "Waypoint").size()).is_equal(1)
	var exits := _named(town, "ZoneExit")
	assert_int(exits.size()).is_equal(1)
	assert_str(exits[0].target).is_equal("graveyard")
	assert_int(town.spawn_points().size()).is_equal(0)

func test_heroes_come_into_town_where_they_arrived_from() -> void:
	assert_vector(_build("town", "gate").hero_start).is_equal(Town.ARRIVALS["gate"])
	assert_vector(_build("town", "waypoint").hero_start).is_equal(Town.ARRIVALS["waypoint"])
	assert_vector(_build("town").hero_start).is_equal(Town.ARRIVALS[""])

func test_the_graveyard_has_monsters_a_checkpoint_and_ways_back_and_down() -> void:
	var graveyard: Graveyard = _build("graveyard", "stairs")
	assert_int(graveyard.spawn_points().size()).is_equal(Graveyard.PACKS.size())
	assert_int(_named(graveyard, "Checkpoint").size()).is_equal(1)
	assert_int(_named(graveyard, "Waypoint").size()).is_equal(1)
	var targets := _named(graveyard, "ZoneExit").map(func(exit: ZoneExit) -> String: return exit.target)
	assert_array(targets).contains_exactly_in_any_order(["town", "crypt"])
	assert_vector(graveyard.hero_start).is_equal(Graveyard.ARRIVALS["stairs"])
