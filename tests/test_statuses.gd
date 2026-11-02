extends GdUnitTestSuite
# Timed buffs and debuffs: War Cry's armour, Frost Nova's chill. They change the stat sheet while they
# last, come off cleanly, and refresh rather than stack when applied again.

const CHILL := [[Stats.MOVE_SPEED, 0.0, -0.5]]

func _dummy() -> Combatant:
	var dummy: Combatant = auto_free(Combatant.new())
	add_child(dummy)
	return dummy

func test_a_status_changes_stats_while_it_lasts() -> void:
	var dummy := _dummy()
	Statuses.of(dummy).apply(&"chill", 2.0, CHILL)
	assert_float(dummy.stats.value(Stats.MOVE_SPEED)).is_equal_approx(3.0, 0.001)
	assert_bool(Statuses.of(dummy).has(&"chill")).is_true()

func test_a_status_comes_off_when_it_runs_out() -> void:
	var dummy := _dummy()
	var statuses := Statuses.of(dummy)
	statuses.apply(&"chill", 2.0, CHILL)
	statuses.tick(1.5)
	assert_bool(statuses.has(&"chill")).is_true()
	statuses.tick(0.6)
	assert_bool(statuses.has(&"chill")).is_false()
	assert_float(dummy.stats.value(Stats.MOVE_SPEED)).is_equal(Stats.DEFAULTS[Stats.MOVE_SPEED])

func test_applying_again_refreshes_rather_than_stacks() -> void:
	var dummy := _dummy()
	var statuses := Statuses.of(dummy)
	statuses.apply(&"chill", 2.0, CHILL)
	statuses.tick(1.5)
	statuses.apply(&"chill", 2.0, CHILL)
	assert_float(dummy.stats.value(Stats.MOVE_SPEED)).is_equal_approx(3.0, 0.001)
	assert_float(statuses.time_left(&"chill")).is_equal_approx(2.0, 0.001)

func test_each_combatant_has_one_status_holder() -> void:
	var dummy := _dummy()
	assert_object(Statuses.of(dummy)).is_same(Statuses.of(dummy))

func test_a_status_visual_goes_when_the_status_does() -> void:
	var dummy := _dummy()
	var statuses := Statuses.of(dummy)
	var aura := Node3D.new()
	statuses.apply(&"war_cry", 1.0, [[Stats.ARMOUR, 20.0, 0.0]], aura)
	assert_object(aura.get_parent()).is_same(dummy)
	statuses.tick(1.1)
	await get_tree().process_frame
	assert_bool(is_instance_valid(aura)).is_false()

func test_refreshing_keeps_one_visual() -> void:
	var dummy := _dummy()
	var statuses := Statuses.of(dummy)
	var first := Node3D.new()
	var second := Node3D.new()
	statuses.apply(&"war_cry", 1.0, [], first)
	statuses.apply(&"war_cry", 1.0, [], second)
	await get_tree().process_frame
	assert_bool(is_instance_valid(first)).is_true()
	assert_bool(is_instance_valid(second)).is_false()

func test_death_clears_statuses() -> void:
	var dummy := _dummy()
	dummy.health = 1.0
	var statuses := Statuses.of(dummy)
	statuses.apply(&"chill", 5.0, CHILL)
	var event := DamageEvent.new()
	event.amount = 5.0
	dummy.take_hit(event)
	assert_bool(statuses.has(&"chill")).is_false()
