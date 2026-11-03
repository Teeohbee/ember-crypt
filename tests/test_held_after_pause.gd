extends GdUnitTestSuite
# The B that closes a menu mustn't also fire the B skill: a button still held when the game comes back
# from a pause is ignored until it's let go.

func after_test() -> void:
	Input.action_release(&"skill_4")
	Input.action_release(&"skill_1")

func test_a_swallowed_button_reads_up_until_let_go_then_works_again() -> void:
	var slot := PlayerSlot.new(3)
	Input.action_press(&"skill_4")
	slot.swallow_held([&"skill_4"])
	assert_bool(slot.pressed(&"skill_4")).is_false()
	Input.action_release(&"skill_4")
	assert_bool(slot.pressed(&"skill_4")).is_false()
	Input.action_press(&"skill_4")
	assert_bool(slot.pressed(&"skill_4")).is_true()

func test_buttons_not_held_are_not_swallowed() -> void:
	var slot := PlayerSlot.new(3)
	slot.swallow_held([&"skill_4"])
	Input.action_press(&"skill_4")
	assert_bool(slot.pressed(&"skill_4")).is_true()

func test_the_hero_swallows_skills_held_through_a_pause() -> void:
	var hero: Hero = auto_free(Hero.new(Session.CLASSES[0], PlayerSlot.new(3)))
	add_child(hero)
	hero.set_physics_process(false)
	Input.action_press(&"skill_1")
	# As if a menu had held the game for a few frames
	hero._last_physics_frame = Engine.get_physics_frames() - 5
	hero._physics_process(1.0 / 60.0)
	assert_bool(hero.slot.pressed(&"skill_1")).is_false()
	assert_float(hero.skill_bar.cooldown_left(0)).is_equal(0.0)
	assert_bool(hero.skill_bar.busy).is_false()

func test_without_a_pause_a_held_skill_fires() -> void:
	var hero: Hero = auto_free(Hero.new(Session.CLASSES[0], PlayerSlot.new(3)))
	add_child(hero)
	hero.set_physics_process(false)
	Input.action_press(&"skill_1")
	hero._physics_process(1.0 / 60.0)
	assert_bool(hero.skill_bar.busy).is_true()
