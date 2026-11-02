extends ScreenSuite
# The options screen: left and right change the focused setting and save it, A flips a toggle, and
# LB / RB move between tabs, wrapping round.

func _options() -> OptionsMenu:
	var options: OptionsMenu = auto_free(OptionsMenu.new())
	get_tree().root.add_child(options)
	options.open()
	await frames(2)
	return options

func test_left_and_right_change_a_volume() -> void:
	await _options()
	var before: int = Settings.get_value("master_volume")
	await press("ui_left")
	assert_int(Settings.get_value("master_volume")).is_equal(before - 1)
	await press("ui_right")
	await press("ui_right")
	assert_int(Settings.get_value("master_volume")).is_equal(before + 1)

func test_a_flips_a_toggle() -> void:
	var options := await _options()
	await press("tab_next")
	assert_int(options.tab).is_equal(1)
	assert_str(focused().text).is_equal("Fullscreen")
	await press("ui_down")
	await press("ui_accept")
	assert_bool(Settings.get_value("vsync")).is_false()

func test_tabs_wrap_round() -> void:
	var options := await _options()
	await press("tab_previous")
	assert_int(options.tab).is_equal(OptionsMenu.TABS.size() - 1)
	await press("tab_next")
	assert_int(options.tab).is_equal(0)

func test_b_closes() -> void:
	var options := await _options()
	var closed := [false]
	options.closed.connect(func() -> void: closed[0] = true)
	await press("ui_cancel")
	assert_bool(closed[0]).is_true()
	assert_bool(options.visible).is_false()
