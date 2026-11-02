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
