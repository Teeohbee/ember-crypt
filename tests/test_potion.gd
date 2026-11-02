extends GdUnitTestSuite
# The health potion on LB: a big heal, then a long wait before the next one. It isn't wasted when
# you're already at full health, and the dead can't drink.

func _drinker(health := 20.0) -> Combatant:
	var drinker: Combatant = auto_free(Combatant.new())
	add_child(drinker)
	drinker.health = health
	return drinker

func test_drinking_heals_a_share_of_max_health() -> void:
	var drinker := _drinker()
	var potion: Potion = auto_free(Potion.new(drinker))
	assert_bool(potion.drink()).is_true()
	assert_float(drinker.health).is_equal_approx(20.0 + 100.0 * Potion.HEAL_FRACTION, 0.001)

func test_a_potion_never_heals_past_full() -> void:
	var drinker := _drinker(90.0)
	var potion: Potion = auto_free(Potion.new(drinker))
	potion.drink()
	assert_float(drinker.health).is_equal(100.0)

func test_after_drinking_it_cools_down() -> void:
	var drinker := _drinker()
	var potion: Potion = auto_free(Potion.new(drinker))
	potion.drink()
	drinker.health = 10.0
	assert_bool(potion.can_drink()).is_false()
	assert_bool(potion.drink()).is_false()
	assert_float(potion.cooldown_fraction()).is_equal_approx(1.0, 0.001)
	potion.tick(Potion.COOLDOWN * 0.5)
	assert_float(potion.cooldown_fraction()).is_equal_approx(0.5, 0.001)
	potion.tick(Potion.COOLDOWN * 0.5)
	assert_bool(potion.can_drink()).is_true()

func test_cooldown_reduction_shortens_the_wait() -> void:
	var drinker := _drinker()
	drinker.stats.set_base(Stats.COOLDOWN_REDUCTION, 0.5)
	var potion: Potion = auto_free(Potion.new(drinker))
	potion.drink()
	assert_float(potion.cooldown_left).is_equal_approx(Potion.COOLDOWN * 0.5, 0.001)

func test_it_isnt_wasted_at_full_health() -> void:
	var drinker := _drinker(100.0)
	var potion: Potion = auto_free(Potion.new(drinker))
	assert_bool(potion.drink()).is_false()
	assert_float(potion.cooldown_left).is_equal(0.0)

func test_the_dead_cant_drink() -> void:
	var drinker := _drinker(0.0)
	var potion: Potion = auto_free(Potion.new(drinker))
	assert_bool(potion.drink()).is_false()
	assert_float(drinker.health).is_equal(0.0)
