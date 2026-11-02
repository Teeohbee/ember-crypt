class_name WorldScreen
extends CanvasLayer
# Base for the screens the world opens - waypoints, stash, vendor. Opening one pauses the game behind
# a dimmed backdrop; B or Start closes it. Screens go on the end of the game scene, so they hear input
# before the pause menu. The game waits for the closing press to be let go before it carries on, so
# the B that shut the stash doesn't also fire the hero's B skill.

signal closed

const RELEASE_FIRST: Array[StringName] = [&"ui_cancel", &"ui_accept", &"pause", &"skill_1", &"skill_4"]

var hero: Hero
var title := ""
var body := VBoxContainer.new()
var prompts: PromptBar
var is_open := false
var _panel := PanelContainer.new()

func _init() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS

# Opens screen for hero, unless the game is already paused or leaving; false (and screen freed) if not
static func show_screen(screen: WorldScreen, for_hero: Hero) -> bool:
	var tree := for_hero.get_tree()
	if tree.paused or SceneManager.is_changing or tree.current_scene == null:
		screen.free()
		return false
	tree.current_scene.add_child(screen)
	screen.open(for_hero)
	return true

func open(for_hero: Hero) -> void:
	hero = for_hero
	is_open = true
	var backdrop := ColorRect.new()
	backdrop.color = Color(UiTheme.VOID, 0.6)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	centre.add_child(_panel)
	body.add_theme_constant_override("separation", 16)
	_panel.add_child(body)
	body.add_child(UiTheme.heading(title, 60))
	body.add_child(UiTheme.divider(480))
	var corner := Control.new()
	corner.set_anchors_preset(Control.PRESET_FULL_RECT)
	corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(corner)
	prompts = PromptBar.in_corner(corner)
	get_tree().paused = true
	Sound.play("open")
	_build()
	prompts.show_prompts(_prompts())
	_panel.modulate.a = 0.0
	create_tween().tween_property(_panel, "modulate:a", 1.0, 0.15)

func close() -> void:
	if not is_open:
		return
	is_open = false
	Sound.play("back")
	hide()
	while _any_held():
		await get_tree().process_frame
	get_tree().paused = false
	closed.emit()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if is_open and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close()

func _any_held() -> bool:
	for action in RELEASE_FIRST:
		if Input.is_action_pressed(action):
			return true
	return false

# Override: fill body
func _build() -> void:
	pass

# Override: the corner hints
func _prompts() -> Array:
	return [["a", "Select"], ["b", "Back"]]
