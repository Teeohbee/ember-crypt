extends ScreenSuite
# Start pauses the game and Start or B resumes it; leaving asks first and defaults to staying, and saying
# no lands back where you were.

const GAME := "res://src/game/game.tscn"

func _pause_menu(game: Node) -> PauseMenu:
	return game.get_node("PauseMenu")

func test_start_pauses_and_start_resumes() -> void:
	var game: Node = await open_screen(GAME)
	await press("pause")
	assert_bool(get_tree().paused).is_true()
	assert_str(focused().text).is_equal("Resume")
	await press("pause")
	assert_bool(get_tree().paused).is_false()
	assert_bool(_pause_menu(game).is_open).is_false()

func test_b_resumes() -> void:
	await open_screen(GAME)
	await press("pause")
	await press("ui_cancel")
	assert_bool(get_tree().paused).is_false()

func test_leaving_asks_first_and_defaults_to_staying() -> void:
	var game: Node = await open_screen(GAME)
	await press("pause")
	await press("ui_down")
	await press("ui_down")
	await press("ui_accept")
	assert_str(focused().text).is_equal("Stay")
	await press("ui_accept")
	assert_str(focused().text).is_equal("Main Menu")
	assert_bool(get_tree().paused).is_true()
	assert_bool(SceneManager.is_changing).is_false()

func test_b_on_the_question_means_stay() -> void:
	await open_screen(GAME)
	await press("pause")
	await press("ui_down")
	await press("ui_down")
	await press("ui_accept")
	await press("ui_cancel")
	assert_str(focused().text).is_equal("Main Menu")
	assert_bool(get_tree().paused).is_true()

func test_pausing_again_starts_on_resume() -> void:
	await open_screen(GAME)
	await press("pause")
	await press("ui_down")
	await press("ui_accept")
	await press("ui_cancel")
	await press("ui_cancel")
	await press("pause")
	assert_str(focused().text).is_equal("Resume")
