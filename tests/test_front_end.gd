extends ScreenSuite
# The front end on a pad: any button leaves the title for the menu, Continue is skipped until there are
# saves, New Game opens class select, left and right change class, and B steps back each time.

const FRONT_END := "res://src/frontend/front_end.tscn"

func test_a_button_on_the_title_opens_the_menu_on_new_game() -> void:
	var front_end: Node = await open_screen(FRONT_END)
	assert_int(front_end.screen).is_equal(front_end.Screen.TITLE)
	await press("ui_accept")
	assert_int(front_end.screen).is_equal(front_end.Screen.MENU)
	assert_str(focused().text).is_equal("New Game")

func test_the_menu_wraps_and_skips_continue() -> void:
	var front_end: Node = await open_screen(FRONT_END)
	await press("ui_accept")
	await press("ui_up")
	assert_str(focused().text).is_equal("Quit")
	await press("ui_down")
	assert_str(focused().text).is_equal("New Game")

func test_new_game_opens_class_select_and_left_right_switch_class() -> void:
	var front_end: Node = await open_screen(FRONT_END)
	await press("ui_accept")
	await press("ui_accept")
	assert_int(front_end.screen).is_equal(front_end.Screen.CLASS_SELECT)
	assert_int(front_end.chosen).is_equal(0)
	await press("ui_right")
	assert_int(front_end.chosen).is_equal(1)
	await press("ui_right")
	assert_int(front_end.chosen).is_equal(0)

func test_b_steps_back_a_screen_at_a_time() -> void:
	var front_end: Node = await open_screen(FRONT_END)
	await press("ui_accept")
	await press("ui_accept")
	await press("ui_cancel")
	assert_int(front_end.screen).is_equal(front_end.Screen.MENU)
	assert_str(focused().text).is_equal("New Game")
	await press("ui_cancel")
	assert_int(front_end.screen).is_equal(front_end.Screen.TITLE)

func test_options_open_from_the_menu_and_b_returns() -> void:
	var front_end: Node = await open_screen(FRONT_END)
	await press("ui_accept")
	await press("ui_down")
	await press("ui_accept")
	assert_int(front_end.screen).is_equal(front_end.Screen.OPTIONS)
	assert_str(focused().text).is_equal("Master volume")
	await press("ui_cancel")
	assert_int(front_end.screen).is_equal(front_end.Screen.MENU)
	assert_str(focused().text).is_equal("Options")
