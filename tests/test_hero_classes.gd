extends GdUnitTestSuite
# Each class's data matches its KayKit model: the animations it names exist, and it holds the props it
# names and nothing else. A typo here would otherwise only show as a T-pose on class select.

func test_each_class_names_animations_its_rig_has() -> void:
	for hero_class in Session.CLASSES:
		var model: HeroModel = auto_free(HeroModel.new(hero_class))
		for animation in [hero_class.idle, hero_class.chosen]:
			assert_bool(model.animations.has_animation(animation)) \
				.override_failure_message("%s has no %s" % [hero_class.display_name, animation]).is_true()

# The rigs come holding every prop they were modelled with; only the class's own should be left
func test_heroes_hold_only_their_own_weapons() -> void:
	for hero_class in Session.CLASSES:
		var model: HeroModel = auto_free(HeroModel.new(hero_class))
		assert_array(Array(model.held_props())).contains_exactly_in_any_order(Array(hero_class.held))

func test_every_class_has_all_four_ratings() -> void:
	for hero_class in Session.CLASSES:
		for rating in ["Toughness", "Damage", "Range", "Difficulty"]:
			assert_int(hero_class.ratings.get(rating, 0)).is_between(1, 5)

# M2's kit sits at X, Y and B; A (index 0) is the primary from M1
func test_each_class_carries_its_combat_kit() -> void:
	var kits := {"barbarian": [&"cleave", &"leap", &"war_cry"], "mage": [&"frost_nova", &"arcane_orb", &"teleport"]}
	for hero_class in Session.CLASSES:
		var ids := []
		for i in range(1, 4):
			ids.append(hero_class.skills[i].id if hero_class.skills.size() > i and hero_class.skills[i] else &"")
		assert_array(ids).is_equal(kits[hero_class.id])

func test_each_skill_names_an_animation_its_rig_has() -> void:
	for hero_class in Session.CLASSES:
		var model: HeroModel = auto_free(HeroModel.new(hero_class))
		for skill in hero_class.skills:
			if skill and skill.animation != "":
				assert_bool(model.animations.has_animation(skill.animation)) \
					.override_failure_message("%s has no %s for %s" % [hero_class.display_name, skill.animation, skill.id]).is_true()

func test_fury_decays_and_arcane_flows_back() -> void:
	var barbarian: HeroClass = Session.CLASSES[0]
	var mage: HeroClass = Session.CLASSES[1]
	assert_float(Stats.new(barbarian.base_stats).value(Stats.POWER_REGEN)).is_less(0.0)
	assert_float(Stats.new(mage.base_stats).value(Stats.POWER_REGEN)).is_greater(0.0)
	assert_float(barbarian.starting_power).is_equal(0.0)
	assert_float(mage.starting_power).is_equal(Stats.new(mage.base_stats).value(Stats.MAX_POWER))

func test_the_barbarian_is_the_tougher() -> void:
	var barbarian := Stats.new(Session.CLASSES[0].base_stats)
	var mage := Stats.new(Session.CLASSES[1].base_stats)
	assert_float(barbarian.value(Stats.MAX_HEALTH)).is_greater(mage.value(Stats.MAX_HEALTH))
