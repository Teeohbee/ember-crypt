extends GdUnitTestSuite
# The hero's legs: getting up to speed, walking or running by how far the stick is pushed, and the
# evade roll. Physics is stepped by hand; the stick is the keyboard's arrows, pressed through Input.

const STEP := 1.0 / 60.0

var hero: Hero

func before_test() -> void:
	hero = auto_free(Hero.new(Session.CLASSES[0], PlayerSlot.new(3)))
	add_child(hero)
	# Steps are driven here, not by the tree
	hero.set_physics_process(false)

func after_test() -> void:
	for action in ["ui_right", "ui_left", "ui_up", "ui_down"]:
		Input.action_release(action)

func _steps(seconds: float) -> void:
	for i in roundi(seconds / STEP):
		hero.motor.physics_step(STEP)

func test_the_hero_gets_up_to_speed_quickly_but_not_at_once() -> void:
	# Right on the stick is right on the screen, which the isometric camera turns on the ground
	var screen_right := GameCamera.ground(Vector2.RIGHT)
	Input.action_press("ui_right")
	_steps(STEP)
	var top_speed := hero.stats.value(Stats.MOVE_SPEED)
	assert_float(hero.velocity.dot(screen_right)).is_between(0.1, top_speed * 0.5)
	_steps(0.3)
	assert_float(hero.velocity.dot(screen_right)).is_equal_approx(top_speed, 0.01)
	assert_float(hero.global_position.dot(screen_right)).is_greater(1.0)
	assert_str(String(hero.model.animations.current_animation)).is_equal(HeroMotor.RUN)

func test_letting_go_slides_to_a_stop_and_idles() -> void:
	Input.action_press("ui_right")
	_steps(0.3)
	Input.action_release("ui_right")
	_steps(0.3)
	assert_float(hero.velocity.length()).is_equal(0.0)
	assert_int(hero.motor.gait).is_equal(HeroMotor.Gait.STILL)

func test_a_gentle_push_walks() -> void:
	# Keys are all or nothing, so the gentle push is handed straight to the motor
	for i in 20:
		hero.motor.move(STEP, Vector2(0, -0.4))
	assert_float(hero.velocity.length()).is_equal_approx(hero.stats.value(Stats.MOVE_SPEED) * HeroMotor.WALK_FRACTION, 0.01)
	assert_str(String(hero.model.animations.current_animation)).is_equal(HeroMotor.WALK)

func test_pulling_lt_rolls_the_way_the_hero_faces() -> void:
	hero.face(Vector3.LEFT)
	var pull := InputEventJoypadMotion.new()
	pull.device = 0
	pull.axis = JOY_AXIS_TRIGGER_LEFT
	pull.axis_value = 1.0
	assert_bool(InputMap.event_is_action(pull, &"evade")).is_true()
	Input.action_press(&"evade")
	hero.motor.physics_step(STEP)
	Input.action_release(&"evade")
	assert_bool(hero.motor.rolling).is_true()
	assert_float(hero.velocity.normalized().dot(Vector3.LEFT)).is_greater(0.99)
	# A press stays "just pressed" for the rest of the frame, even released; let it pass
	await get_tree().process_frame

func test_the_hero_turns_to_face_the_way_they_go() -> void:
	Input.action_press("ui_left")
	_steps(0.3)
	assert_float(hero.facing().dot(GameCamera.ground(Vector2.LEFT))).is_greater(0.99)

func test_a_roll_covers_its_distance_untouchable_at_first() -> void:
	assert_bool(hero.motor.roll(Vector3.BACK)).is_true()
	_steps(STEP * 2)
	assert_bool(hero.invulnerable).is_true()
	_steps(HeroMotor.ROLL_SECONDS)
	assert_bool(hero.motor.rolling).is_false()
	assert_bool(hero.invulnerable).is_false()
	assert_float(hero.global_position.z).is_equal_approx(HeroMotor.ROLL_DISTANCE, 0.3)

func test_the_i_frames_end_before_the_roll_does() -> void:
	hero.motor.roll(Vector3.BACK)
	_steps(HeroMotor.ROLL_IFRAMES + STEP)
	assert_bool(hero.motor.rolling).is_true()
	assert_bool(hero.invulnerable).is_false()

func test_rolls_cannot_be_chained_back_to_back() -> void:
	hero.motor.roll(Vector3.BACK)
	assert_bool(hero.motor.roll(Vector3.LEFT)).is_false()
	_steps(HeroMotor.ROLL_SECONDS + STEP)
	assert_bool(hero.motor.roll(Vector3.LEFT)).is_false()
	_steps(HeroMotor.ROLL_COOLDOWN + STEP)
	assert_bool(hero.motor.roll(Vector3.LEFT)).is_true()

func test_no_rolling_out_of_a_swing() -> void:
	var skill := SkillDef.new()
	skill.hit_time = 10.0
	skill.recovery = 1.0
	hero.skill_bar.set_skill(0, skill)
	hero.skill_bar.use(0, Vector3.FORWARD)
	assert_bool(hero.motor.roll(Vector3.BACK)).is_false()

func test_a_flick_of_the_right_stick_rolls_once_until_it_recentres() -> void:
	assert_bool(HeroMotor.flicked(true, Vector2(0.9, 0))).is_true()
	assert_bool(HeroMotor.flicked(true, Vector2(0.4, 0))).is_false()
	assert_bool(HeroMotor.flicked(false, Vector2(0.9, 0))).is_false()
