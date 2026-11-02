extends ScreenSuite
# The skills screen on a pad: the D-pad opens it over a paused game, rows list the class's skills with
# locked ones saying when they come, left and right step through only the runes the hero has reached,
# and B closes it and unpauses.

func _hero() -> Hero:
	var hero_class: HeroClass = Session.CLASSES[0].duplicate()
	var bash := SkillDef.new()
	bash.id = &"bash"
	bash.display_name = "Bash"
	var cleave := SkillDef.new()
	cleave.id = &"cleave"
	cleave.display_name = "Cleave"
	cleave.unlock_level = 4
	hero_class.skills = [bash, cleave]
	var hero: Hero = auto_free(Hero.new(hero_class, PlayerSlot.new(5)))
	add_child(hero)
	return hero

func _screen(hero: Hero) -> SkillsScreen:
	var screen: SkillsScreen = auto_free(SkillsScreen.new(hero.slot))
	add_child(screen)
	return screen

func test_the_dpad_opens_it_paused_and_b_closes_it() -> void:
	var screen := _screen(_hero())
	await press("skills_menu")
	assert_bool(screen.is_open).is_true()
	assert_bool(get_tree().paused).is_true()
	assert_object(focused()).is_same(screen.rows[0])
	await press("ui_right")
	assert_str(screen.rows[0].rune_label.text).contains("No rune")
	await press("ui_cancel")
	assert_bool(screen.is_open).is_false()
	assert_bool(get_tree().paused).is_false()

func test_the_skills_button_closes_it_without_changing_a_rune() -> void:
	var hero := _hero()
	hero.progress.set_level(8, 0)
	var screen := _screen(hero)
	screen.open()
	var event := InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_DPAD_LEFT
	for pressed in [true, false]:
		event.pressed = pressed
		Input.parse_input_event(event.duplicate())
		await frames(2)
	assert_bool(screen.is_open).is_false()
	assert_object(hero.progress.rune_for(&"bash")).is_null()

func test_locked_skills_say_when_and_empty_slots_cant_be_focused() -> void:
	var screen := _screen(_hero())
	screen.open()
	assert_str(screen.rows[1].rune_label.text).is_equal("Unlocks at level 4")
	assert_bool(screen.rows[1].cycle(1)).is_false()
	assert_int(screen.rows[2].focus_mode).is_equal(Control.FOCUS_NONE)
	assert_str(screen.rows[2].name_label.text).is_equal("Empty")

func test_runes_cycle_through_only_those_reached() -> void:
	var hero := _hero()
	var screen := _screen(hero)
	screen.open()
	var bash := screen.rows[0]
	assert_bool(bash.cycle(1)).is_false()
	hero.progress.set_level(8, 0)
	assert_array(bash.choices()).is_equal([&"", &"bash_frenzy", &"bash_onslaught"])
	bash.cycle(1)
	assert_object(hero.progress.rune_for(&"bash").id).is_equal(&"bash_frenzy")
	assert_str(bash.rune_label.text).contains("Frenzy")
	bash.cycle(1)
	bash.cycle(1)
	assert_object(hero.progress.rune_for(&"bash")).is_null()
	bash.cycle(-1)
	assert_object(hero.progress.rune_for(&"bash").id).is_equal(&"bash_onslaught")
