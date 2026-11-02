extends GdUnitTestSuite
# A hero's progress: kills give XP, levelling up grows the class's stats and heals, skills stay locked
# until their level, and runes go on (once unlocked) and come off again.

const MINION := preload("res://src/monsters/defs/skeleton_minion.tres")

var _levelled := []

func _record_level(_hero: Hero, level: int) -> void:
	_levelled.append(level)

func before_test() -> void:
	_levelled.clear()
	Events.hero_levelled_up.connect(_record_level)

func after_test() -> void:
	Events.hero_levelled_up.disconnect(_record_level)

func _skill(id: StringName, unlock := 1) -> SkillDef:
	var skill := SkillDef.new()
	skill.id = id
	skill.display_name = String(id).capitalize()
	skill.unlock_level = unlock
	skill.hit_time = 0.0
	return skill

# A Barbarian with Bash (level 1) and Cleave (level 4), on a slot of its own so Session isn't touched
func _hero() -> Hero:
	var hero_class: HeroClass = Session.CLASSES[0].duplicate()
	hero_class.skills = [_skill(&"bash"), _skill(&"cleave", 4)]
	var hero: Hero = auto_free(Hero.new(hero_class, PlayerSlot.new(7)))
	add_child(hero)
	return hero

func _kill_minion() -> void:
	var monster: Monster = auto_free(Monster.new(MINION))
	Events.monster_killed.emit(monster, DamageEvent.new())

func test_a_kill_gives_the_monsters_xp() -> void:
	var hero := _hero()
	_kill_minion()
	assert_int(hero.xp).is_equal(MINION.xp)
	assert_int(hero.level).is_equal(1)

func test_a_dead_hero_earns_nothing() -> void:
	var hero := _hero()
	hero.health = 0.0
	_kill_minion()
	assert_int(hero.xp).is_equal(0)

func test_levelling_up_grows_stats_heals_and_announces_it() -> void:
	var hero := _hero()
	var health_before := hero.max_health()
	hero.health = 1.0
	hero.progress.gain_xp(Levels.xp_to_next(1) + 5)
	assert_int(hero.level).is_equal(2)
	assert_int(hero.xp).is_equal(5)
	var growth: float = hero.hero_class.growth[Stats.MAX_HEALTH]
	assert_float(hero.max_health()).is_equal_approx(health_before + growth, 0.001)
	assert_float(hero.health).is_equal_approx(hero.max_health(), 0.001)
	assert_array(_levelled).is_equal([2])

func test_every_class_grows_with_level() -> void:
	for hero_class in Session.CLASSES:
		assert_bool(hero_class.growth.is_empty()).is_false()
		assert_float(float(hero_class.growth.get(Stats.MAX_HEALTH, 0.0))).is_greater(0.0)

func test_skills_stay_locked_until_their_level() -> void:
	var hero := _hero()
	assert_bool(hero.skill_bar.can_use(0)).is_true()
	assert_bool(hero.skill_bar.is_unlocked(1)).is_false()
	assert_bool(hero.skill_bar.can_use(1)).is_false()
	assert_bool(hero.skill_bar.use(1, Vector3.FORWARD)).is_false()
	hero.progress.set_level(4, 0)
	assert_bool(hero.skill_bar.can_use(1)).is_true()

func test_monsters_skill_bars_ignore_unlock_levels() -> void:
	var monster: Monster = auto_free(Monster.new(MINION))
	monster.skill_bar.set_skill(0, _skill(&"bite", 20))
	assert_bool(monster.skill_bar.is_unlocked(0)).is_true()

func test_a_level_up_lists_what_it_unlocked() -> void:
	var hero := _hero()
	var unlocks := hero.progress.unlocks_at(4)
	assert_array(unlocks).contains(["New skill: Cleave"])
	assert_array(hero.progress.unlocks_at(3)).contains(["New rune: Frenzy"])

func test_a_rune_goes_on_once_unlocked_and_comes_off() -> void:
	var hero := _hero()
	var bash: SkillDef = hero.hero_class.skills[0]
	assert_bool(hero.progress.set_rune(&"bash", &"bash_frenzy")).is_false()
	assert_object(hero.skill_bar.skills[0]).is_same(bash)
	hero.progress.set_level(3, 0)
	assert_bool(hero.progress.set_rune(&"bash", &"bash_frenzy")).is_true()
	assert_str(String(hero.skill_bar.skills[0].params.rune)).is_equal("bash_frenzy")
	assert_object(hero.progress.rune_for(&"bash").id).is_equal(&"bash_frenzy")
	assert_bool(hero.progress.set_rune(&"bash", &"")).is_true()
	assert_object(hero.skill_bar.skills[0]).is_same(bash)

func test_a_rune_for_another_skill_is_refused() -> void:
	var hero := _hero()
	hero.progress.set_level(20, 0)
	assert_bool(hero.progress.set_rune(&"bash", &"cleave_rupture")).is_false()
	assert_bool(hero.progress.set_rune(&"teleport", &"teleport_wormhole")).is_false()

func test_progress_round_trips_through_a_dictionary() -> void:
	var hero := _hero()
	hero.progress.set_level(9, 42)
	hero.progress.set_rune(&"bash", &"bash_onslaught")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(hero.progress.to_dict()))
	var again := _hero()
	again.progress.load_dict(saved)
	assert_int(again.level).is_equal(9)
	assert_int(again.xp).is_equal(42)
	assert_object(again.progress.rune_for(&"bash").id).is_equal(&"bash_onslaught")
	assert_float(again.max_health()).is_equal_approx(hero.max_health(), 0.001)
	assert_float(again.health).is_equal_approx(again.max_health(), 0.001)

func test_broken_progress_data_is_clamped_and_unknown_runes_dropped() -> void:
	var hero := _hero()
	hero.progress.load_dict({"level": 999, "xp": -5, "runes": {"bash": "nonsense", "cleave": 4}})
	assert_int(hero.level).is_equal(Levels.MAX_LEVEL)
	assert_int(hero.xp).is_equal(0)
	assert_object(hero.progress.rune_for(&"bash")).is_null()
