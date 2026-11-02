extends GdUnitTestSuite
# Packs, elites and their affixes. Rolls are seeded; time is stepped by hand.

const STEP := 1.0 / 60.0

var _world: Node3D

func before_test() -> void:
	_world = auto_free(Node3D.new())
	add_child(_world)

func _rng(seed_value := 7) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng

func _monster(id := &"skeleton_minion", at := Vector3.ZERO) -> Monster:
	var monster: Monster = auto_free(Monster.new(MonsterLibrary.find(id)))
	_world.add_child(monster)
	monster.global_position = at
	monster.brain.set_physics_process(false)
	return monster

func _hero(at: Vector3) -> Combatant:
	var hero: Combatant = auto_free(Combatant.new())
	hero.team = Combatant.Team.HEROES
	hero.stats = Stats.new({Stats.MAX_HEALTH: 1000.0})
	_world.add_child(hero)
	hero.global_position = at
	return hero

func test_affix_rolls_are_distinct_and_repeatable() -> void:
	var first := Elites.roll_affixes(_rng(), 3)
	var again := Elites.roll_affixes(_rng(), 3)
	assert_int(first.size()).is_equal(3)
	assert_array(first).is_equal(again)
	assert_bool(first[0] != first[1] and first[1] != first[2] and first[0] != first[2]).is_true()

func test_cannot_roll_more_affixes_than_exist() -> void:
	assert_int(Elites.roll_affixes(_rng(), 99).size()).is_equal(Elites.AFFIXES.size())

func test_names_are_repeatable() -> void:
	assert_str(Elites.roll_name(_rng(3))).is_equal(Elites.roll_name(_rng(3)))

func test_an_elite_is_tougher_and_wears_its_name() -> void:
	var monster := _monster()
	var before := monster.max_health()
	Elites.promote(monster, [Elites.find(&"fast")], "Grimjaw the Hollow")
	assert_bool(monster.elite).is_true()
	assert_array(monster.affixes).contains([&"fast"])
	assert_float(monster.max_health()).is_equal_approx(before * (1.0 + Elites.HEALTH_BONUS), 0.01)
	assert_float(monster.health).is_equal(monster.max_health())
	assert_float(monster.stats.value(Stats.MOVE_SPEED)).is_greater(monster.def.base_stats[Stats.MOVE_SPEED])
	var plate: NamePlate = monster.find_child("NamePlate", false, false)
	assert_str(plate.title.text).is_equal("Grimjaw the Hollow")
	assert_str(plate.subtitle.text).is_equal("Fast")

func test_the_name_plate_bar_follows_health() -> void:
	var monster := _monster()
	Elites.promote(monster, [], "Knell")
	var plate: NamePlate = monster.find_child("NamePlate", false, false)
	monster.health = monster.max_health() * 0.25
	monster.health_changed.emit(monster.health, monster.max_health())
	assert_float(plate.fraction()).is_equal_approx(0.25, 0.001)

func test_a_pack_spawns_together_and_shares_its_aggro() -> void:
	var point: SpawnPoint = auto_free(SpawnPoint.new())
	point.pack = load("res://src/monsters/packs/warband.tres")
	_world.add_child(point)
	var spawned := point.spawn()
	for monster in spawned:
		auto_free(monster)
	assert_int(spawned.size()).is_equal(point.pack.members.size())
	assert_object(spawned[0].def.id).is_equal(&"skeleton_warrior")
	var hero := _hero(Vector3(0, 0, 40))
	spawned[0].brain.alert(hero)
	for monster in spawned:
		assert_object(monster.brain.target).is_same(hero)

func test_elite_chance_decides_whether_a_pack_is_led_by_an_elite() -> void:
	for chance in [0.0, 1.0]:
		var point: SpawnPoint = auto_free(SpawnPoint.new())
		point.count = 3
		point.elite_chance = chance
		point.rng = _rng()
		_world.add_child(point)
		var spawned := point.spawn()
		for monster in spawned:
			auto_free(monster)
		assert_bool(spawned[0].elite).is_equal(chance > 0.5)
		assert_bool(spawned[1].elite).is_false()

func test_shielding_comes_up_in_a_fight_then_drops() -> void:
	var monster := _monster()
	var shielding := ShieldingAffix.new(monster)
	monster.add_child(shielding)
	monster.brain.target = _hero(Vector3(0, 0, 3))
	shielding._physics_process(ShieldingAffix.EVERY + STEP)
	assert_bool(monster.brain.immune).is_true()
	assert_bool(shielding.bubble.visible).is_true()
	shielding._physics_process(ShieldingAffix.LASTS)
	assert_bool(monster.brain.immune).is_false()

func test_molten_pools_burn_whoever_stands_in_them() -> void:
	var monster := _monster()
	var inside := _hero(Vector3(0.5, 0, 0))
	var outside := _hero(Vector3(5, 0, 0))
	var pool := Hazard.pool(monster, MoltenAffix.BURN, Vector3.ZERO, 1.1, 2.0)
	_world.add_child(pool)
	pool._physics_process(STEP)
	assert_float(inside.health).is_less(inside.max_health())
	assert_float(outside.health).is_equal(outside.max_health())

func test_a_molten_blast_waits_for_its_telegraph() -> void:
	var monster := _monster()
	var hero := _hero(Vector3(1, 0, 0))
	var blast := Hazard.blast(monster, MoltenAffix.BURN, Vector3.ZERO, 3.0, 1.0)
	_world.add_child(blast)
	blast._physics_process(0.5)
	assert_float(hero.health).is_equal(hero.max_health())
	blast._physics_process(0.6)
	assert_float(hero.health).is_less(hero.max_health())
