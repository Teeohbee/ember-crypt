extends GdUnitTestSuite
# The level curve and XP rules: each level costs more than the last, XP rolls over through several
# levels at once, it stops at the cap, and kills of tougher or elite monsters are worth more.

func test_each_level_costs_more_than_the_last() -> void:
	assert_int(Levels.xp_to_next(1)).is_greater(0)
	for level in range(1, Levels.MAX_LEVEL - 1):
		assert_int(Levels.xp_to_next(level + 1)).is_greater(Levels.xp_to_next(level))

func test_the_cap_needs_no_more_xp() -> void:
	assert_int(Levels.xp_to_next(Levels.MAX_LEVEL)).is_equal(0)

func test_xp_below_the_next_level_just_adds_up() -> void:
	assert_array(Levels.add_xp(1, 0, 5)).is_equal([1, 5])

func test_xp_rolls_over_into_the_next_level() -> void:
	var needed := Levels.xp_to_next(1)
	assert_array(Levels.add_xp(1, needed - 1, 3)).is_equal([2, 2])

func test_a_big_award_climbs_several_levels() -> void:
	var award := Levels.xp_to_next(1) + Levels.xp_to_next(2) + Levels.xp_to_next(3) + 7
	assert_array(Levels.add_xp(1, 0, award)).is_equal([4, 7])

func test_xp_stops_at_the_cap() -> void:
	assert_array(Levels.add_xp(Levels.MAX_LEVEL - 1, 0, 100000000)).is_equal([Levels.MAX_LEVEL, 0])
	assert_array(Levels.add_xp(Levels.MAX_LEVEL, 0, 50)).is_equal([Levels.MAX_LEVEL, 0])

func test_an_even_kill_is_worth_the_monsters_xp() -> void:
	assert_int(Levels.kill_xp(10, 3, 3, false)).is_equal(10)

func test_tougher_monsters_are_worth_more_and_weaker_less_but_never_nothing() -> void:
	assert_int(Levels.kill_xp(10, 6, 3, false)).is_greater(10)
	assert_int(Levels.kill_xp(10, 1, 3, false)).is_less(10)
	assert_int(Levels.kill_xp(10, 1, 30, false)).is_greater(0)

func test_elites_are_worth_more() -> void:
	assert_int(Levels.kill_xp(10, 3, 3, true)).is_greater(Levels.kill_xp(10, 3, 3, false))

func test_growth_adds_per_level_after_the_first() -> void:
	var growth := {Stats.MAX_HEALTH: 10.0, Stats.DAMAGE: 1.5}
	var sheet := Stats.new({Stats.MAX_HEALTH: 100.0})
	Levels.apply_growth(sheet, growth, 1)
	assert_float(sheet.value(Stats.MAX_HEALTH)).is_equal(100.0)
	Levels.apply_growth(sheet, growth, 5)
	assert_float(sheet.value(Stats.MAX_HEALTH)).is_equal(140.0)
	assert_float(sheet.value(Stats.DAMAGE)).is_equal(Stats.DEFAULTS[Stats.DAMAGE] + 6.0)
	# Applying again replaces rather than stacks
	Levels.apply_growth(sheet, growth, 2)
	assert_float(sheet.value(Stats.MAX_HEALTH)).is_equal(110.0)
