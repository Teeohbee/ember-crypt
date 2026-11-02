extends GdUnitTestSuite
# The two primaries, Bash and Magic Missile, and the melee step-lunge. Effects are fired straight away
# and time is stepped by hand.

const MINION := preload("res://src/monsters/defs/skeleton_minion.tres")
const BASH := preload("res://src/skills/barbarian/bash.tres")
const MISSILE := preload("res://src/skills/mage/magic_missile.tres")
const STEP := 1.0 / 60.0

func after_test() -> void:
	Feedback.reset()

func test_each_class_leads_with_its_primary() -> void:
	assert_object(Session.CLASSES[0].skills[0]).is_same(BASH)
	assert_object(Session.CLASSES[1].skills[0]).is_same(MISSILE)

func test_a_melee_swing_steps_in_to_reach_its_target() -> void:
	var hero := _hero(0, Vector3.ZERO)
	var monster := _monster(Vector3(0, 0, -4.5))
	assert_bool(hero.skill_bar.use(0, Vector3.FORWARD)).is_true()
	var shove: Shove = hero.get_node("Shove")
	for i in 60:
		shove._physics_process(STEP)
	var gap := (monster.global_position - hero.global_position).length()
	assert_float(gap).is_between(1.0, BASH.params.strike_range + 0.1)

func test_bash_hits_knocks_back_and_builds_fury() -> void:
	var hero := _hero(0, Vector3.ZERO)
	var monster := _monster(Vector3(0, 0, -1.5))
	monster.stats.set_base(Stats.MAX_HEALTH, 1000.0)
	monster.revive()
	BASH.instantiate_effect().execute(hero, BASH, monster, Vector3.FORWARD)
	assert_float(monster.health).is_less(1000.0)
	var shove: Shove = monster.get_node("Shove")
	for i in 60:
		shove._physics_process(STEP)
	assert_float(monster.global_position.z).is_less(-2.0)

func test_bash_without_a_target_still_catches_whatever_is_in_front() -> void:
	var hero := _hero(0, Vector3.ZERO)
	var monster := _monster(Vector3(0.4, 0, -1.6))
	var before := monster.health
	BASH.instantiate_effect().execute(hero, BASH, null, Vector3.FORWARD)
	assert_float(monster.health).is_less(before)

func test_bash_generates_fury_through_the_skill_bar() -> void:
	var hero := _hero(0, Vector3.ZERO)
	_monster(Vector3(0, 0, -1.5))
	var skill: SkillDef = BASH.duplicate()
	skill.hit_time = 0.0
	hero.skill_bar.set_skill(0, skill)
	hero.power = 0.0
	hero.skill_bar.use(0, Vector3.FORWARD)
	assert_float(hero.power).is_equal(BASH.generate)

func test_bash_landing_on_whatever_is_in_front_builds_fury() -> void:
	var hero := _hero(0, Vector3.ZERO)
	_monster(Vector3(0.4, 0, -1.6))
	hero.power = 0.0
	BASH.instantiate_effect().execute(hero, BASH, null, Vector3.FORWARD)
	assert_float(hero.power).is_equal(BASH.generate)

func test_a_bash_that_whiffs_builds_no_fury() -> void:
	var hero := _hero(0, Vector3.ZERO)
	var fled := _monster(Vector3(0, 0, -6))
	var skill: SkillDef = BASH.duplicate()
	skill.hit_time = 0.0
	hero.skill_bar.set_skill(0, skill)
	hero.power = 0.0
	hero.skill_bar.use_on(0, fled)
	assert_float(fled.health).is_equal(fled.max_health())
	assert_float(hero.power).is_equal(0.0)

func test_a_missile_curls_onto_its_target_and_hurts_it() -> void:
	var hero := _hero(1, Vector3.ZERO)
	# Off to one side of where the hero aims: the bolt has to bend to reach it
	var monster := _monster(Vector3(3, 0, -8))
	var before := monster.health
	var missile := ArcaneMissile.fire(hero, MISSILE, monster, Vector3.FORWARD)
	for i in 120:
		if not missile.flying:
			break
		missile._physics_process(STEP)
	assert_float(monster.health).is_less(before)

func test_a_missile_with_nothing_to_hit_goes_out_and_returns_to_the_pool() -> void:
	var hero := _hero(1, Vector3.ZERO)
	var missile := ArcaneMissile.fire(hero, MISSILE, null, Vector3.FORWARD)
	for i in 120:
		missile._physics_process(STEP)
	assert_bool(missile.visible).is_false()
	assert_object(ArcaneMissile.fire(hero, MISSILE, null, Vector3.FORWARD)).is_same(missile)

func _hero(class_index: int, at: Vector3) -> Hero:
	var hero: Hero = auto_free(Hero.new(Session.CLASSES[class_index], PlayerSlot.new(3)))
	hero.position = at
	add_child(hero)
	hero.set_physics_process(false)
	return hero

func _monster(at: Vector3) -> Monster:
	var monster: Monster = auto_free(Monster.new(MINION))
	monster.position = at
	add_child(monster)
	return monster
