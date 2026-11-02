extends GdUnitTestSuite
# The first boss: phases by health, what it picks to do, and a fight stepped by hand.

func test_phases_come_at_sixty_and_thirty_percent() -> void:
	assert_int(BossBrain.phase_for(1.0)).is_equal(0)
	assert_int(BossBrain.phase_for(0.61)).is_equal(0)
	assert_int(BossBrain.phase_for(0.6)).is_equal(1)
	assert_int(BossBrain.phase_for(0.31)).is_equal(1)
	assert_int(BossBrain.phase_for(0.3)).is_equal(2)
	assert_int(BossBrain.phase_for(0.0)).is_equal(2)

func test_it_chases_until_in_reach_then_swings() -> void:
	var all_ready := [true, true, true]
	assert_str(BossBrain.choose(0, 12.0, all_ready, 3.0, 6.0)).is_equal("chase")
	assert_str(BossBrain.choose(0, 2.0, [true, false, false], 3.0, 6.0)).is_equal("cleave")
	assert_str(BossBrain.choose(0, 2.0, [false, false, false], 3.0, 6.0)).is_equal("wait")

func test_the_slam_comes_first_when_it_is_ready_and_in_range() -> void:
	assert_str(BossBrain.choose(0, 5.0, [true, true, true], 3.0, 6.0)).is_equal("slam")
	assert_str(BossBrain.choose(0, 2.0, [true, true, true], 3.0, 6.0)).is_equal("slam")

func test_it_only_raises_the_dead_once_wounded() -> void:
	assert_str(BossBrain.choose(0, 2.0, [true, false, true], 3.0, 6.0)).is_equal("cleave")
	assert_str(BossBrain.choose(1, 2.0, [true, true, true], 3.0, 6.0)).is_equal("summon")
	assert_str(BossBrain.choose(2, 20.0, [true, true, true], 3.0, 6.0)).is_equal("summon")

func test_the_boss_def_is_a_big_skeleton_with_three_attacks() -> void:
	var def := MonsterLibrary.find(BossSpawn.BOSS)
	assert_bool(def.is_boss).is_true()
	assert_float(def.scale).is_greater(1.5)
	assert_int(def.skills.size()).is_equal(3)
	assert_object(def.weapon_right).is_not_null()

func test_a_stepped_fight_wakes_it_turns_it_and_rouses_it_at_each_phase() -> void:
	var world: Node3D = auto_free(Node3D.new())
	get_tree().root.add_child(world)
	var point := BossSpawn.new()
	world.add_child(point)
	var engaged := []
	var on_engaged := func(boss: Monster) -> void: engaged.append(boss)
	Events.boss_engaged.connect(on_engaged)
	var boss: Monster = point.spawn()[0]
	var brain: BossBrain = boss.get_node("BossBrain")
	assert_bool(boss.brain.process_mode == Node.PROCESS_MODE_DISABLED).is_true()
	brain.step(0.1)
	assert_int(brain.state).is_equal(BossBrain.State.DORMANT)
	var hero := Hero.new(Session.CLASSES[0], PlayerSlot.new(3))
	hero.position = Vector3(0, 0, 8)
	world.add_child(hero)
	brain.step(0.1)
	Events.boss_engaged.disconnect(on_engaged)
	assert_array(engaged).contains_exactly([boss])
	assert_int(brain.state).is_equal(BossBrain.State.ROARING)
	for i in 30:
		brain.step(0.1)
	assert_int(brain.state).is_equal(BossBrain.State.FIGHTING)
	# Far off, it walks at the hero
	assert_float(boss.velocity.length()).is_greater(0.0)
	var phases := []
	brain.phase_changed.connect(func(phase: int) -> void: phases.append(phase))
	boss.take_hit(_hit(hero, boss.max_health() * 0.45))
	assert_array(phases).contains_exactly([1])
	assert_int(brain.state).is_equal(BossBrain.State.ROARING)
	assert_float(boss.stats.value(Stats.ATTACK_SPEED)).is_greater(1.0)
	boss.take_hit(_hit(hero, boss.max_health() * 0.3))
	assert_array(phases).contains_exactly([1, 2])
	boss.take_hit(_hit(hero, boss.max_health()))
	assert_int(brain.state).is_equal(BossBrain.State.DEAD)

func test_the_slam_lands_ahead_and_hurts_only_who_stands_there() -> void:
	var world: Node3D = auto_free(Node3D.new())
	get_tree().root.add_child(world)
	var boss := MonsterLibrary.spawn(BossSpawn.BOSS, world, Vector3.ZERO)
	boss.face(Vector3.BACK)
	var slam: SkillDef = boss.def.skills[BossBrain.SLAM]
	var under := Hero.new(Session.CLASSES[0], PlayerSlot.new(3))
	under.position = BossSlam.landing(boss, Vector3.BACK, slam)
	world.add_child(under)
	var clear := Hero.new(Session.CLASSES[0], PlayerSlot.new(4))
	clear.position = Vector3(0, 0, -10)
	world.add_child(clear)
	slam.instantiate_effect().execute(boss, slam, null, Vector3.BACK)
	assert_float(under.health).is_less(under.max_health())
	assert_float(clear.health).is_equal(clear.max_health())

func _hit(source: Combatant, amount: float) -> DamageEvent:
	var event := DamageEvent.new()
	event.source = source
	event.amount = amount
	return event

func test_the_boss_bar_appears_on_the_roar_and_follows_its_health() -> void:
	var world: Node3D = auto_free(Node3D.new())
	get_tree().root.add_child(world)
	var bar: BossBar = auto_free(BossBar.new(PlayerSlot.new(3)))
	get_tree().root.add_child(bar)
	var boss := MonsterLibrary.spawn(BossSpawn.BOSS, world, Vector3.ZERO)
	Events.boss_engaged.emit(boss)
	assert_bool(bar.visible).is_true()
	assert_str(bar._title.text).is_equal(boss.def.display_name)
	boss.take_hit(_hit(boss, boss.max_health() * 0.25))
	assert_float(bar.fraction).is_equal_approx(0.75, 0.001)
	boss.take_hit(_hit(boss, boss.max_health()))
	assert_str(bar._title.text).is_equal("Slain")
