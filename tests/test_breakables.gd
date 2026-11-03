extends GdUnitTestSuite
# Barrels, crates and pumpkins: one blow breaks them, they're fair game for a hero's skills but never
# a monster, aim assist would rather hit a skeleton, and breaking one pays no XP but may spill gold.

const MINION := preload("res://src/monsters/defs/skeleton_minion.tres")
const BASH := preload("res://src/skills/barbarian/bash.tres")

func after_test() -> void:
	Feedback.reset()

func test_one_blow_breaks_a_barrel_and_it_stops_being_in_the_way() -> void:
	var hero := _hero()
	var barrel := _barrel(Vector3(0, 0, -1.5))
	BASH.instantiate_effect().execute(hero, BASH, null, Vector3.FORWARD)
	assert_bool(barrel.alive).is_false()
	await get_tree().physics_frame
	assert_bool(barrel.get_node("Shape").disabled).is_true()
	assert_bool(barrel.model.visible).is_false()

func test_breakables_are_a_heroes_hostiles_but_not_a_monsters_and_not_monsters() -> void:
	var hero := _hero()
	var barrel := _barrel(Vector3(0, 0, -3))
	var monster: Monster = auto_free(Monster.new(MINION))
	monster.position = Vector3(4, 0, 0)
	add_child(monster)
	assert_array(hero.hostiles()).contains([barrel])
	assert_array(monster.hostiles()).not_contains([barrel])
	assert_bool(barrel.is_in_group(&"monsters")).is_false()

func test_aim_assist_would_rather_hit_a_skeleton_than_a_barrel() -> void:
	var hero := _hero()
	var barrel := _barrel(Vector3(0, 0, -2))
	var monster: Monster = auto_free(Monster.new(MINION))
	monster.position = Vector3(0.8, 0, -2.6)
	add_child(monster)
	var picked := Targeting.best_target(Vector3.ZERO, Vector3.FORWARD, hero.hostiles(), 5.0, 110.0)
	assert_object(picked).is_same(monster)
	assert_object(Targeting.best_target(Vector3.ZERO, Vector3.FORWARD, [barrel], 5.0, 110.0)).is_same(barrel)

func test_breaking_one_pays_no_xp_but_can_spill_gold() -> void:
	var hero := _hero()
	var barrel := _barrel(Vector3(0, 0, -1.5))
	barrel.gold_chance = 1.0
	var xp := hero.xp
	BASH.instantiate_effect().execute(hero, BASH, barrel, Vector3.FORWARD)
	assert_int(hero.xp).is_equal(xp)
	var gold := find_children("*", "FloorDrop", true, false)
	assert_int(gold.size()).is_equal(1)

func test_the_crypt_and_graveyard_have_things_to_smash() -> void:
	var dungeon: Dungeon = auto_free(Dungeon.new(5))
	dungeon.build()
	assert_int(dungeon.find_children("*", "Breakable", true, false).size()).is_greater(12)
	var graveyard: Graveyard = auto_free(Graveyard.new())
	graveyard.build()
	assert_int(graveyard.find_children("*", "Breakable", true, false).size()).is_greater(5)

func _hero() -> Hero:
	var hero: Hero = auto_free(Hero.new(Session.CLASSES[0], PlayerSlot.new(3)))
	add_child(hero)
	hero.set_physics_process(false)
	return hero

func _barrel(at: Vector3) -> Breakable:
	var barrel: Breakable = auto_free(Breakable.make("barrel_small"))
	barrel.position = at
	# Gold only where a test asks for it, so no stray coins outlive their test
	barrel.gold_chance = 0.0
	add_child(barrel)
	return barrel

func test_a_barrel_nearby_doesnt_stop_a_from_picking_things_up() -> void:
	var hero := _hero()
	_barrel(Vector3(0, 0, -1.2))
	assert_bool(hero.pickup.hostile_close()).is_false()
