@abstract
class_name ScreenSuite
extends GdUnitTestSuite
# Base for suites that drive real screens with real input. Settings are kept in a scratch file, so a
# test never writes the player's settings.json; characters likewise, so none of the player's show up
# and none are written; nothing is left paused, and the world is back to the test room.

# One file per process, so suites running side by side in other worktrees don't share it
var scratch_path := "user://test_settings_%d.json" % OS.get_process_id()
var _real_path: String
var saves_path := "user://test_characters_screens_%d.json" % OS.get_process_id()
var _real_saves_path: String

func before_test() -> void:
	_real_path = Settings.path
	Settings.path = scratch_path
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch_path))
	Settings.load_from_disk()
	_real_saves_path = SaveGame.path
	SaveGame.path = saves_path
	DirAccess.remove_absolute(ProjectSettings.globalize_path(saves_path))
	SaveGame.load_from_disk()
	SceneManager.speed_scale = 20.0

func after_test() -> void:
	get_tree().paused = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch_path))
	Settings.path = _real_path
	Settings.load_from_disk()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(saves_path))
	SaveGame.path = _real_saves_path
	SaveGame.load_from_disk()
	SceneManager.speed_scale = 1.0
	# Choosing a character sends Session to their zone (a new one's is the town)
	Session.zone_id = ""
	Session.enter_world([], 0)

# A screen added to the tree for this test only
func open_screen(path: String) -> Node:
	var screen: Node = auto_free(load(path).instantiate())
	get_tree().root.add_child(screen)
	await frames(2)
	return screen

# Presses and releases an action as a pad would, then lets the screen react.
func press(action: String) -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
		await frames(2)

func frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame

func focused() -> Control:
	return get_tree().root.gui_get_focus_owner()
