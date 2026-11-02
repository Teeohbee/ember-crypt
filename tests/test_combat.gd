extends GdUnitTestSuite
# The damage maths and the stat sheet: pure, so seeded and exact.

func _rng(seed_value := 1) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng

func _event(amount: float, kind := DamageEvent.Kind.PHYSICAL) -> DamageEvent:
	var event := DamageEvent.new()
	event.amount = amount
	event.kind = kind
	return event

func test_stats_add_flats_then_scale_by_percents() -> void:
	var stats := Stats.new({Stats.DAMAGE: 10.0})
	stats.add_modifier(&"axe", Stats.DAMAGE, 5.0)
	stats.add_modifier(&"ring", Stats.DAMAGE, 0.0, 0.2)
	assert_float(stats.value(Stats.DAMAGE)).is_equal_approx(18.0, 0.001)

func test_clearing_a_source_takes_its_modifiers_off() -> void:
	var stats := Stats.new({Stats.ARMOUR: 10.0})
	stats.add_modifier(&"helm", Stats.ARMOUR, 20.0)
	stats.clear_source(&"helm")
	assert_float(stats.value(Stats.ARMOUR)).is_equal(10.0)

func test_unset_stats_use_defaults() -> void:
	assert_float(Stats.new().value(Stats.MOVE_SPEED)).is_equal(Stats.DEFAULTS[Stats.MOVE_SPEED])

func test_armour_mitigates_physical_damage() -> void:
	var attacker := Stats.new({Stats.CRIT_CHANCE: 0.0})
	var event := Combat.resolve(_event(100.0), attacker, Stats.new({Stats.ARMOUR: 100.0}), _rng())
	assert_float(event.amount).is_equal_approx(50.0, 0.001)

func test_resist_mitigates_elements_but_is_capped() -> void:
	var attacker := Stats.new({Stats.CRIT_CHANCE: 0.0})
	var event := Combat.resolve(_event(100.0, DamageEvent.Kind.FIRE), attacker, Stats.new({Stats.RESIST: 0.95}), _rng())
	assert_float(event.amount).is_equal_approx(25.0, 0.001)

func test_a_crit_adds_crit_damage() -> void:
	var attacker := Stats.new({Stats.CRIT_CHANCE: 1.0, Stats.CRIT_DAMAGE: 1.0})
	var event := Combat.resolve(_event(10.0), attacker, Stats.new(), _rng())
	assert_bool(event.crit).is_true()
	assert_float(event.amount).is_equal_approx(20.0, 0.001)

func test_targeting_prefers_the_one_you_point_at() -> void:
	var ahead: Combatant = auto_free(_dummy(Vector3(0, 0, -5)))
	var nearer_but_aside: Combatant = auto_free(_dummy(Vector3(2, 0, -1)))
	var picked := Targeting.best_target(Vector3.ZERO, Vector3.FORWARD, [ahead, nearer_but_aside], 8.0)
	assert_object(picked).is_same(ahead)

func test_targeting_ignores_anything_behind_or_out_of_reach() -> void:
	var behind: Combatant = auto_free(_dummy(Vector3(0, 0, 3)))
	var far: Combatant = auto_free(_dummy(Vector3(0, 0, -20)))
	assert_object(Targeting.best_target(Vector3.ZERO, Vector3.FORWARD, [behind, far], 8.0)).is_null()

func _dummy(at: Vector3) -> Combatant:
	var dummy := Combatant.new()
	dummy.position = at
	dummy.health = 10.0
	add_child(dummy)
	return dummy
