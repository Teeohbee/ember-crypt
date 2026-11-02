@abstract
class_name ScreenSuite
extends GdUnitTestSuite
# Base for suites that drive real screens with real input. Settings are kept in a scratch file, so a
# test never writes the player's settings.json, and nothing is left paused.

# One file per process, so suites running side by side in other worktrees don't share it
var scratch_path := "user://test_settings_%d.json" % OS.get_process_id()
var _real_path: String

func before_test() -> void:
	_real_path = Settings.path
	Settings.path = scratch_path
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch_path))
	Settings.load_from_disk()
	SceneManager.speed_scale = 20.0

func after_test() -> void:
	get_tree().paused = false
	# A hit-stop left running would slow the next test
	Feedback.reset()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch_path))
	Settings.path = _real_path
	Settings.load_from_disk()
	SceneManager.speed_scale = 1.0

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
