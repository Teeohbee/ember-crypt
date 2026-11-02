extends ScreenSuite
# Getting about: A uses what's in reach unless a monster is close, waypoints list what you've found,
# and heroes keep their things between zones.

var _session := {}

func before_test() -> void:
	super()
	_session = {"zone_id": Session.zone_id, "arrival": Session.arrival, "waypoints": Session.waypoints.duplicate(),
		"carried": Session.carried, "checkpoint": Session.checkpoint}

func after_test() -> void:
	for key: String in _session:
		Session.set(key, _session[key])
	super()

func _hero(parent: Node) -> Hero:
	var hero := Hero.new(Session.CLASSES[0], PlayerSlot.new(3))
	parent.add_child(hero)
	return hero

func _world() -> Node3D:
	var world: Node3D = auto_free(Node3D.new())
	get_tree().root.add_child(world)
	return world

func test_a_uses_the_nearest_thing_in_reach_unless_a_monster_is_close() -> void:
	var world := _world()
	var hero := _hero(world)
	var near := Interactable.new("Stash", 2.5)
	near.position = Vector3(1, 0, 0)
	var far := Interactable.new("Vendor", 2.5)
	far.position = Vector3(2, 0, 0)
	world.add_child(far)
	world.add_child(near)
	var out_of_reach := Interactable.new("Waypoint", 2.5)
	out_of_reach.position = Vector3(-5, 0, 0)
	world.add_child(out_of_reach)
	assert_object(Interactable.find_for(hero)).is_same(near)
	var used := []
	near.used.connect(func(by: Hero) -> void: used.append(by))
	assert_bool(hero._interact()).is_true()
	assert_array(used).contains_exactly([hero])
	MonsterLibrary.spawn(&"skeleton_minion", world, Vector3(0, 0, 4))
	assert_object(Interactable.find_for(hero)).is_null()

func test_a_waypoint_is_learnt_by_touching_it() -> void:
	Session.waypoints = ["town"]
	var waypoint: Waypoint = auto_free(Waypoint.new("graveyard"))
	assert_bool(waypoint.discover()).is_true()
	assert_bool(waypoint.discover()).is_false()
	assert_array(Session.waypoints).contains_exactly(["town", "graveyard"])

func test_the_waypoint_menu_lights_only_known_places_and_b_closes_it() -> void:
	Session.waypoints = ["town", "crypt"]
	var world := _world()
	var hero := _hero(world)
	var menu := WaypointMenu.new("town")
	world.add_child(menu)
	menu.open(hero)
	await frames(1)
	assert_bool(get_tree().paused).is_true()
	var buttons := menu.menu.get_children()
	assert_bool(buttons[0].disabled).is_true()   # here
	assert_bool(buttons[1].disabled).is_true()   # the graveyard, not found yet
	assert_str(buttons[1].text).is_equal("Undiscovered")
	assert_bool(buttons[2].disabled).is_false()
	assert_object(focused()).is_same(buttons[2])
	await press("ui_cancel")
	await frames(2)
	assert_bool(get_tree().paused).is_false()
	assert_bool(is_instance_valid(menu) and menu.is_open).is_false()

func test_heroes_carry_their_things_to_the_next_zone() -> void:
	var world := _world()
	var hero := _hero(world)
	hero.inventory.add_gold(140)
	hero.level = 4
	hero.health = 37.0
	var snapshot := Travel.snapshot(hero)
	Session.carried = {3: snapshot}
	var arrived := _hero(world)
	Travel.restore(arrived)
	assert_int(arrived.inventory.gold).is_equal(140)
	assert_int(arrived.level).is_equal(4)
	assert_float(arrived.health).is_equal(37.0)

func test_preparing_to_travel_sets_where_and_forgets_the_checkpoint() -> void:
	Session.checkpoint = Vector3.ONE
	Travel.prepare("crypt", "waypoint")
	assert_str(Session.zone_id).is_equal("crypt")
	assert_str(Session.arrival).is_equal("waypoint")
	assert_vector(Session.checkpoint).is_equal(Vector3.INF)
