extends GdUnitTestSuite
# The combat HUD: health and power globes either side of the potion and six skill sockets. Widgets
# are driven by hand here; one scene test checks the bar is wired to a real hero.

func test_a_globe_shows_how_full_it_is() -> void:
	var globe: ResourceGlobe = auto_free(ResourceGlobe.new(Color.RED))
	globe.set_values(30.0, 120.0)
	assert_float(globe.fraction).is_equal_approx(0.25, 0.001)
	assert_str(globe.readout).is_equal("30")

func test_a_globe_with_nothing_to_hold_is_empty_not_broken() -> void:
	var globe: ResourceGlobe = auto_free(ResourceGlobe.new(Color.RED))
	globe.set_values(10.0, 0.0)
	assert_float(globe.fraction).is_equal(0.0)

func test_a_globe_trails_what_was_lost_then_catches_up() -> void:
	var globe: ResourceGlobe = auto_free(ResourceGlobe.new(Color.RED))
	globe.set_values(100.0, 100.0)
	globe.snap()
	globe.set_values(40.0, 100.0)
	assert_float(globe.trail).is_equal(1.0)
	for i in 120:
		globe._process(1.0 / 60.0)
	assert_float(globe.trail).is_equal_approx(0.4, 0.001)

func test_a_globe_gaining_doesnt_trail() -> void:
	var globe: ResourceGlobe = auto_free(ResourceGlobe.new(Color.RED))
	globe.set_values(40.0, 100.0)
	globe.snap()
	globe.set_values(90.0, 100.0)
	assert_float(globe.trail).is_equal_approx(0.9, 0.001)

func _skill(name: String, cost := 0.0) -> SkillDef:
	var skill := SkillDef.new()
	skill.display_name = name
	skill.cost = cost
	return skill

func test_an_empty_socket_says_so() -> void:
	var socket: SkillSlot = auto_free(SkillSlot.new("a"))
	socket.show_skill(null, 0.0, 0.0, true)
	assert_bool(socket.empty).is_true()

func test_a_socket_shows_its_skill_and_cooldown() -> void:
	var socket: SkillSlot = auto_free(SkillSlot.new("x"))
	socket.show_skill(_skill("Frost Nova"), 0.5, 4.5, true)
	assert_bool(socket.empty).is_false()
	assert_str(socket.initials).is_equal("FN")
	assert_float(socket.cooldown).is_equal(0.5)
	assert_str(socket.countdown).is_equal("5")

func test_a_socket_shows_no_countdown_in_the_last_second() -> void:
	var socket: SkillSlot = auto_free(SkillSlot.new("x"))
	socket.show_skill(_skill("Leap"), 0.1, 0.6, true)
	assert_str(socket.countdown).is_equal("")

func test_a_socket_flashes_when_its_skill_comes_ready() -> void:
	var socket: SkillSlot = auto_free(SkillSlot.new("x"))
	socket.show_skill(_skill("Leap"), 0.2, 1.0, true)
	socket.show_skill(_skill("Leap"), 0.0, 0.0, true)
	assert_float(socket.ready_flash).is_greater(0.0)

func test_the_bar_mirrors_the_hero() -> void:
	var slot := PlayerSlot.new(3)
	var hero: Hero = auto_free(Hero.new(Session.CLASSES[1], slot))
	add_child(hero)
	var bar: ActionBar = auto_free(ActionBar.new(slot))
	add_child(bar)
	hero.health = hero.max_health() * 0.5
	hero.power = 30.0
	hero.skill_bar.use(2, Vector3.FORWARD)
	bar.refresh()
	assert_float(bar.health_globe.fraction).is_equal_approx(0.5, 0.001)
	assert_float(bar.power_globe.fraction).is_equal_approx(0.0, 0.001)
	assert_int(bar.skill_slots.size()).is_equal(SkillBar.SLOTS)
	assert_bool(bar.skill_slots[1].empty).is_false()
	assert_bool(bar.skill_slots[4].empty).is_true()
	# Arcane Orb was cast; Frost Nova still costs more than what's left
	assert_bool(bar.skill_slots[1].affordable).is_false()

func test_the_bar_copes_without_a_hero() -> void:
	var bar: ActionBar = auto_free(ActionBar.new(PlayerSlot.new(5)))
	add_child(bar)
	bar.refresh()
	assert_float(bar.health_globe.fraction).is_equal(0.0)
