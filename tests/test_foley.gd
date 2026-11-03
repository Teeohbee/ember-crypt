extends GdUnitTestSuite
# The recorded sounds: every set has takes, every underlay plays under a real synth sound, a hero's feet
# fall in step on the zone's ground, and a waking pack rattles once.

const STEP := 1.0 / 60.0

var heard: Array[String] = []

func before_test() -> void:
	heard.clear()
	Sound.played.connect(_hear)

func after_test() -> void:
	Sound.played.disconnect(_hear)
	Input.action_release("ui_right")
	Session.zone_id = ""

func _hear(sound_name: String) -> void:
	heard.append(sound_name)

func test_every_set_has_takes() -> void:
	for set_name: String in Foley.SETS:
		assert_array(Foley.load_set(set_name)).override_failure_message("%s has no takes" % set_name).is_not_empty()

func test_every_underlay_joins_a_real_synth_sound_to_a_real_set() -> void:
	for synth: String in Foley.UNDERLAYS:
		assert_bool(Compositions.SOUNDS.has(synth)).override_failure_message("no synth sound %s" % synth).is_true()
		assert_bool(Foley.SETS.has(Foley.UNDERLAYS[synth])).is_true()

func test_a_synth_sound_brings_its_underlay() -> void:
	Sound.play("impact")
	assert_array(heard).is_equal(["impact", "hit"])

func test_a_sound_without_an_underlay_plays_alone() -> void:
	Sound.play("tick")
	assert_array(heard).is_equal(["tick"])

func test_a_set_plays_by_name() -> void:
	Sound.play("skeleton_wake")
	assert_array(heard).is_equal(["skeleton_wake"])

func test_running_steps_once_a_stride_on_the_crypt_floor() -> void:
	Session.zone_id = "crypt"
	var hero: Hero = auto_free(Hero.new(Session.CLASSES[0], PlayerSlot.new(3)))
	add_child(hero)
	hero.set_physics_process(false)
	Input.action_press("ui_right")
	for i in 120:
		hero.motor.physics_step(STEP)
	var steps := heard.count("footstep_stone")
	# Two seconds at a run, the first footfall on setting off
	var expected := 1 + floori(hero.global_position.x / HeroMotor.RUN_STRIDE)
	assert_int(steps).is_between(expected - 1, expected + 1)
	assert_int(steps).is_greater(3)

func test_the_graveyard_is_grass_underfoot() -> void:
	assert_str(Foley.footsteps_for("graveyard")).is_equal("footstep_grass")
	assert_str(Foley.footsteps_for("crypt")).is_equal("footstep_stone")
	assert_str(Foley.footsteps_for("town")).is_equal("footstep_stone")

func test_standing_still_makes_no_footsteps() -> void:
	var hero: Hero = auto_free(Hero.new(Session.CLASSES[0], PlayerSlot.new(3)))
	add_child(hero)
	hero.set_physics_process(false)
	for i in 60:
		hero.motor.physics_step(STEP)
	assert_array(heard.filter(func(s: String) -> bool: return s.begins_with("footstep"))).is_empty()

func test_a_waking_pack_rattles_once() -> void:
	var world: Node3D = auto_free(Node3D.new())
	add_child(world)
	var pack: Array[Monster] = []
	for i in 3:
		var monster: Monster = auto_free(Monster.new(MonsterLibrary.find(&"skeleton_minion")))
		world.add_child(monster)
		monster.global_position = Vector3(i * 2, 0, 0)
		monster.brain.set_physics_process(false)
		pack.append(monster)
	for monster in pack:
		monster.brain.pack = pack
	var hero: Combatant = auto_free(Combatant.new())
	hero.team = Combatant.Team.HEROES
	hero.stats = Stats.new({Stats.MAX_HEALTH: 1000.0})
	world.add_child(hero)
	hero.global_position = Vector3(0, 0, 20)
	pack[0].brain.alert(hero)
	assert_int(heard.count("skeleton_wake")).is_equal(1)
