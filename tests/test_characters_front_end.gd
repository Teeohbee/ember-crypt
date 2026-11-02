extends ScreenSuite
# Characters in the front end: with a save the menu opens on Continue, which plays the last character;
# the character list plays or deletes (after asking); New Game makes a new character of the class
# chosen.

const FRONT_END := "res://src/frontend/front_end.tscn"

func _menu(front_end: Node) -> void:
	await press("ui_accept")
	assert_int(front_end.screen).is_equal(front_end.Screen.MENU)

func test_continue_plays_the_last_character() -> void:
	var older := SaveGame.create(Session.CLASSES[0])
	var newer := SaveGame.create(Session.CLASSES[1])
	SaveGame.current_id = ""
	var front_end: Node = await open_screen(FRONT_END)
	await _menu(front_end)
	assert_str(focused().text).is_equal("Continue")
	assert_str(front_end._resume.text).contains(newer.name)
	await press("ui_accept")
	assert_int(front_end.screen).is_equal(front_end.Screen.LEAVING)
	assert_str(SaveGame.current_id).is_equal(newer.id)
	assert_object(Session.hero_class).is_same(Session.CLASSES[1])
	assert_str(older.id).is_not_equal(newer.id)

func test_the_list_plays_whoever_is_picked() -> void:
	var older := SaveGame.create(Session.CLASSES[0])
	SaveGame.create(Session.CLASSES[1])
	var front_end: Node = await open_screen(FRONT_END)
	await _menu(front_end)
	await press("ui_down")
	assert_str(focused().text).is_equal("Characters")
	await press("ui_accept")
	assert_int(front_end.screen).is_equal(front_end.Screen.CHARACTERS)
	await press("ui_down")
	assert_str(focused().text).is_equal(older.name)
	await press("ui_accept")
	assert_str(SaveGame.current_id).is_equal(older.id)
	assert_object(Session.hero_class).is_same(Session.CLASSES[0])

func test_deleting_asks_first_and_the_last_one_returns_to_the_menu() -> void:
	var only := SaveGame.create(Session.CLASSES[0])
	var front_end: Node = await open_screen(FRONT_END)
	await _menu(front_end)
	await press("ui_down")
	await press("ui_accept")
	await press("menu_delete")
	assert_str(focused().text).is_equal("Keep")
	await press("ui_cancel")
	assert_int(SaveGame.characters.size()).is_equal(1)
	assert_str(focused().text).is_equal(only.name)
	await press("menu_delete")
	await press("ui_down")
	await press("ui_accept")
	assert_array(SaveGame.characters).is_empty()
	assert_int(front_end.screen).is_equal(front_end.Screen.MENU)
	assert_str(focused().text).is_equal("New Game")

func test_new_game_makes_a_character_of_the_chosen_class() -> void:
	var front_end: Node = await open_screen(FRONT_END)
	await _menu(front_end)
	await press("ui_accept")
	await press("ui_right")
	await press("ui_accept")
	assert_int(SaveGame.characters.size()).is_equal(1)
	assert_str(SaveGame.current()["class"]).is_equal("mage")
	assert_object(Session.hero_class).is_same(Session.CLASSES[1])
