extends GdUnitTestSuite
# The monster state machine: idle, chase, attack, hurt, die, and the archetypes' variations. Time is
# stepped by hand (think() and _physics_process), never waited for.

const STEP := 1.0 / 60.0

# Zones are Node3Ds, and summons and telegraphs land in the monster's parent
var _world: Node3D

func before_test() -> void:
	_world = auto_free(Node3D.new())
	add_child(_world)

func _monster(id: StringName, at := Vector3.ZERO) -> Monster:
	var monster: Monster = auto_free(Monster.new(MonsterLibrary.find(id)))
	_world.add_child(monster)
	monster.global_position = at
	monster.brain.set_physics_process(false)
	monster.skill_bar.set_process(false)
	monster.brain._physics_process(STEP)
	return monster

func _hero(at: Vector3) -> Combatant:
	var hero: Combatant = auto_free(Combatant.new())
	hero.team = Combatant.Team.HEROES
	hero.stats = Stats.new({Stats.MAX_HEALTH: 1000.0})
	_world.add_child(hero)
	hero.global_position = at
	return hero

func _hit(monster: Monster, from: Combatant, amount := 1.0) -> DamageEvent:
	var event := DamageEvent.new()
	event.source = from
	event.target = monster
	event.amount = amount
	monster.take_hit(event)
	return event

func _step(monster: Monster, seconds: float) -> void:
	for i in int(seconds / STEP):
		monster.brain._physics_process(STEP)

func test_stays_idle_with_no_hero_in_range() -> void:
	var monster := _monster(&"skeleton_minion")
	_hero(Vector3(0, 0, 30))
	monster.brain.think()
	assert_int(monster.brain.state).is_equal(MonsterBrain.State.IDLE)
	assert_vector(monster.velocity).is_equal(Vector3.ZERO)

func test_chases_a_hero_that_comes_in_range() -> void:
	var monster := _monster(&"skeleton_minion")
	_hero(Vector3(0, 0, 8))
	monster.brain.think()
	monster.brain._physics_process(STEP)
	assert_int(monster.brain.state).is_equal(MonsterBrain.State.CHASE)
	assert_float(monster.velocity.normalized().dot(Vector3.BACK)).is_greater(0.99)

func test_attacks_when_in_reach_then_chases_again() -> void:
	var monster := _monster(&"skeleton_minion")
	var hero := _hero(Vector3(0, 0, 1.2))
	monster.brain.think()
	assert_int(monster.brain.state).is_equal(MonsterBrain.State.ATTACK)
	assert_bool(monster.skill_bar.busy).is_true()
	hero.global_position = Vector3(0, 0, 6)
	monster.skill_bar._process(5.0)
	monster.brain.think()
	assert_int(monster.brain.state).is_equal(MonsterBrain.State.CHASE)

func test_a_hit_makes_it_flinch_then_recover_but_not_again_straight_away() -> void:
	var monster := _monster(&"skeleton_minion")
	var hero := _hero(Vector3(0, 0, 8))
	_hit(monster, hero)
	assert_int(monster.brain.state).is_equal(MonsterBrain.State.HURT)
	_step(monster, MonsterBrain.HURT_SECONDS + 0.05)
	assert_int(monster.brain.state).is_equal(MonsterBrain.State.CHASE)
	_hit(monster, hero)
	assert_int(monster.brain.state).is_not_equal(MonsterBrain.State.HURT)

func test_being_hit_from_out_of_range_still_wakes_it() -> void:
	var monster := _monster(&"skeleton_minion")
	var hero := _hero(Vector3(0, 0, 30))
	_hit(monster, hero)
	assert_object(monster.brain.target).is_same(hero)

func test_dies_and_stops() -> void:
	var monster := _monster(&"skeleton_minion")
	var hero := _hero(Vector3(0, 0, 8))
	monster.brain.think()
	_hit(monster, hero, 1000.0)
	assert_int(monster.brain.state).is_equal(MonsterBrain.State.DIE)
	monster.brain.think()
	assert_int(monster.brain.state).is_equal(MonsterBrain.State.DIE)

func test_waking_one_wakes_its_pack() -> void:
	var one := _monster(&"skeleton_minion")
	var two := _monster(&"skeleton_minion", Vector3(3, 0, 0))
	one.brain.pack = [one, two]
	two.brain.pack = [one, two]
	var hero := _hero(Vector3(0, 0, 30))
	one.brain.alert(hero)
	assert_object(two.brain.target).is_same(hero)
	assert_int(two.brain.state).is_equal(MonsterBrain.State.CHASE)

func test_a_kiter_backs_away_from_a_hero_too_close() -> void:
	var rogue := _monster(&"skeleton_rogue")
	var hero := _hero(Vector3(0, 0, 2))
	rogue.brain.alert(hero)
	rogue.skill_bar._cooldowns[0] = 10.0
	rogue.brain.think()
	rogue.brain._physics_process(STEP)
	assert_int(rogue.brain.state).is_equal(MonsterBrain.State.CHASE)
	assert_float(rogue.velocity.normalized().dot(Vector3.FORWARD)).is_greater(0.99)

func test_a_shooter_shoots_from_range_without_closing_in() -> void:
	var rogue := _monster(&"skeleton_rogue")
	_hero(Vector3(0, 0, 8))
	rogue.brain.think()
	assert_int(rogue.brain.state).is_equal(MonsterBrain.State.ATTACK)
	rogue.brain._physics_process(STEP)
	assert_vector(rogue.velocity).is_equal(Vector3.ZERO)

func test_a_shield_blocks_hits_from_the_front_only() -> void:
	var warrior := _monster(&"skeleton_warrior")
	warrior.face(Vector3.BACK)
	var front := _hit(warrior, _hero(Vector3(0, 0, 3)), 10.0)
	var behind := _hit(warrior, _hero(Vector3(0, 0, -3)), 10.0)
	assert_float(front.amount).is_equal_approx(10.0 * (1.0 - warrior.def.block), 0.001)
	assert_float(behind.amount).is_equal(10.0)

func test_immune_takes_nothing() -> void:
	var monster := _monster(&"skeleton_minion")
	monster.brain.immune = true
	_hit(monster, _hero(Vector3(0, 0, 3)), 10.0)
	assert_float(monster.health).is_equal(monster.max_health())

func test_a_caster_summons_until_it_has_enough_then_casts_instead() -> void:
	var mage := _monster(&"skeleton_mage")
	var hero := _hero(Vector3(0, 0, 8))
	mage.brain.alert(hero)
	assert_int(mage.brain.pick_skill()).is_equal(0)
	var cap: int = mage.def.skills[0].params["max_alive"]
	for i in cap:
		mage.brain.summons.append(_monster(&"skeleton_minion", Vector3(i, 0, -3)))
	assert_int(mage.brain.pick_skill()).is_equal(1)

func test_summoning_raises_minions_that_join_the_fight() -> void:
	var mage := _monster(&"skeleton_mage")
	var hero := _hero(Vector3(0, 0, 8))
	mage.brain.alert(hero)
	var skill: SkillDef = mage.def.skills[0]
	skill.instantiate_effect().execute(mage, skill, hero, Vector3.BACK)
	assert_int(mage.brain.living_summons()).is_equal(skill.params["count"])
	for raised in mage.brain.summons:
		auto_free(raised)
		assert_object(raised.brain.target).is_same(hero)

func test_gives_up_past_its_leash_and_walks_home() -> void:
	var monster := _monster(&"skeleton_minion")
	var hero := _hero(Vector3(0, 0, 40))
	monster.brain.alert(hero)
	monster.global_position = Vector3(0, 0, monster.def.leash + 1.0)
	monster.brain.think()
	monster.brain._physics_process(STEP)
	assert_object(monster.brain.target).is_null()
	assert_int(monster.brain.state).is_equal(MonsterBrain.State.IDLE)
	assert_float(monster.velocity.normalized().dot(Vector3.FORWARD)).is_greater(0.99)

func test_a_big_attack_is_telegraphed_for_its_wind_up() -> void:
	var warrior := _monster(&"skeleton_warrior")
	var hero := _hero(Vector3(0, 0, 2))
	assert_bool(warrior.skill_bar.use_on(0, hero)).is_true()
	var telegraphs := find_children("*", "Telegraph", true, false)
	assert_int(telegraphs.size()).is_equal(1)
	assert_float(telegraphs[0].seconds).is_equal_approx(warrior.def.skills[0].hit_time, 0.001)
	assert_bool(warrior.skill_bar.use_on(1, hero)).is_false()

func test_a_swing_misses_a_hero_who_stepped_out_of_reach() -> void:
	var minion := _monster(&"skeleton_minion")
	var near := _hero(Vector3(0, 0, 1.5))
	var gone := _hero(Vector3(0, 0, -6))
	var skill: SkillDef = minion.def.skills[0]
	skill.instantiate_effect().execute(minion, skill, gone, Vector3.BACK)
	assert_float(near.health).is_less(near.max_health())
	assert_float(gone.health).is_equal(gone.max_health())

func test_a_bolt_flies_into_the_hero_in_its_path_and_stops() -> void:
	var rogue := _monster(&"skeleton_rogue")
	var hero := _hero(Vector3(0, 0, 6))
	var bolt := Bolt.new(rogue, rogue.def.skills[0], Vector3.BACK)
	_world.add_child(bolt)
	bolt.global_position = Vector3(0, 1.2, 0.6)
	for i in 30:
		if bolt.is_queued_for_deletion():
			break
		bolt._physics_process(STEP)
	assert_float(hero.health).is_less(hero.max_health())
	assert_bool(bolt.is_queued_for_deletion()).is_true()
