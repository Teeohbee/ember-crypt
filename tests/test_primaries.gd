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

func test_bash_catches_up_to_three_in_its_arc_and_nothing_behind() -> void:
	var hero := _hero(0, Vector3.ZERO)
	var target := _monster(Vector3(0, 0, -1.5))
	var aside := [_monster(Vector3(-1.1, 0, -1.2)), _monster(Vector3(1.1, 0, -1.2)), _monster(Vector3(0, 0, -2.4))]
	var behind := _monster(Vector3(0, 0, 1.5))
	for monster: Monster in aside + [target, behind]:
		monster.stats.set_base(Stats.MAX_HEALTH, 1000.0)
		monster.revive()
	hero.power = 0.0
	BASH.instantiate_effect().execute(hero, BASH, target, Vector3.FORWARD)
	assert_float(target.health).is_less(1000.0)
	var caught := aside.filter(func(monster: Monster) -> bool: return monster.health < 1000.0)
	assert_int(caught.size()).is_equal(BASH.params.max_targets - 1)
	assert_float(behind.health).is_equal(1000.0)
	assert_float(hero.power).is_equal(BASH.generate * BASH.params.max_targets)

func test_bash_swings_faster_than_its_animation_was_drawn() -> void:
	var hero := _hero(0, Vector3.ZERO)
	hero.play_skill_animation(BASH, 1.0)
	assert_float(hero.model.animations.speed_scale).is_equal_approx(BASH.params.anim_speed, 0.001)
	assert_float(BASH.hit_time).is_less_equal(0.25)

func test_a_killing_blow_throws_the_body_further() -> void:
	var hero := _hero(0, Vector3.ZERO)
	var tough := _monster(Vector3(0, 0, -1.5))
	tough.stats.set_base(Stats.MAX_HEALTH, 1000.0)
	tough.revive()
	var weak := _monster(Vector3(10, 0, -1.5))
	weak.health = 1.0
	BASH.instantiate_effect().execute(hero, BASH, tough, Vector3.FORWARD)
	hero.global_position = Vector3(10, 0, 0)
	BASH.instantiate_effect().execute(hero, BASH, weak, Vector3.FORWARD)
	for monster in [tough, weak]:
		var shove: Shove = monster.get_node("Shove")
		for i in 90:
			if is_instance_valid(shove):
				shove._physics_process(STEP)
	assert_float(-weak.global_position.z - 1.5).is_greater((-tough.global_position.z - 1.5) * 2.0)

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

func test_a_swing_after_the_last_target_was_freed_still_finds_a_new_one() -> void:
	var hero := _hero(0, Vector3.ZERO)
	var gone := Monster.new(MINION)
	add_child(gone)
	hero.skill_bar.last_target = gone
	gone.free()
	var next := _monster(Vector3(0, 0, -1.5))
	var skill: SkillDef = BASH.duplicate()
	skill.hit_time = 0.0
	hero.skill_bar.set_skill(0, skill)
	assert_bool(hero.skill_bar.use(0, Vector3.FORWARD)).is_true()
	assert_object(hero.skill_bar.last_target).is_same(next)
