extends Node3D
# Title, main menu, options and class select, all in front of one crypt so the world never cuts
# away: the camera glides between shots and the UI fades over it. B steps back a screen.
#
#   title --A--> menu --New Game--> class select --A--> (the crypt)
#                  \--Options--> options

enum Screen { TITLE, MENU, OPTIONS, CLASS_SELECT, LEAVING }

const GAME := "res://src/game/game.tscn"
const SHOT_SECONDS := 1.4

# Camera shots: where it sits and what it looks at
const TITLE_SHOT := [Vector3(0, 4.2, 13.0), Vector3(0, 2.6, -6.0)]
const MENU_SHOT := [Vector3(-3.5, 3.4, 10.5), Vector3(-0.5, 2.0, -4.0)]
# Per hero: close on them, framed off-centre so the info panel has the other half of the screen
const CLASS_SHOTS := [
	[Vector3(-0.4, 2.3, 4.6), Vector3(-1.4, 1.5, -1.5)],
	[Vector3(0.4, 2.3, 4.6), Vector3(1.4, 1.5, -1.5)],
]

var screen := Screen.TITLE
var chosen := 0

var _camera := Camera3D.new()
var _look_at := TITLE_SHOT[1]
var _shot_tween: Tween
var _time := 0.0
var _diorama := Diorama.new()

var _ui := CanvasLayer.new()
var _title := Control.new()
var _press_start: Control
var _menu := MenuList.new()
var _menu_layer := Control.new()
var _menu_box := VBoxContainer.new()
var _options := OptionsMenu.new()
var _class_panel := ClassPanel.new()
var _prompts: PromptBar

func _ready() -> void:
	add_child(_diorama)
	_camera.fov = 46.0
	_camera.position = TITLE_SHOT[0]
	add_child(_camera)
	add_child(_ui)
	_build_title()
	_build_menu()
	_options.hide()
	_options.closed.connect(func() -> void: _show(Screen.MENU))
	_centre(_options)
	_class_panel.hide()
	_ui.add_child(_class_panel)
	_prompts = PromptBar.in_corner(_root_control())
	_show(Screen.TITLE)
	Music.play("title")
	_diorama.spotlight(-1, 0.01)
	if get_tree().current_scene == self and not SceneManager.is_changing:
		SceneManager.reveal()

func _process(delta: float) -> void:
	_time += delta
	# A slow drift so the room never sits dead still
	var drift := Vector3(sin(_time * 0.21) * 0.25, sin(_time * 0.17) * 0.12, 0)
	_camera.look_at(_look_at + drift)
	if _press_start:
		_press_start.modulate.a = 0.55 + 0.45 * sin(_time * 2.6)

func _unhandled_input(event: InputEvent) -> void:
	match screen:
		Screen.TITLE:
			if _is_any_press(event):
				get_viewport().set_input_as_handled()
				Sound.play("confirm")
				_show(Screen.MENU)
		Screen.MENU:
			if event.is_action_pressed("ui_cancel"):
				get_viewport().set_input_as_handled()
				Sound.play("back")
				_show(Screen.TITLE)
		Screen.CLASS_SELECT:
			if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
				get_viewport().set_input_as_handled()
				_choose(chosen + (-1 if event.is_action_pressed("ui_left") else 1))
			elif event.is_action_pressed("ui_accept"):
				get_viewport().set_input_as_handled()
				_enter_crypt()
			elif event.is_action_pressed("ui_cancel"):
				get_viewport().set_input_as_handled()
				Sound.play("back")
				_show(Screen.MENU)

func _show(next: Screen) -> void:
	screen = next
	# The menu fades rather than vanishing, and a fading button would keep focus and eat the stick
	get_viewport().gui_release_focus()
	_fade(_title, next == Screen.TITLE)
	_fade(_menu_layer, next == Screen.MENU)
	_fade(_class_panel, next == Screen.CLASS_SELECT)
	match next:
		Screen.TITLE:
			_glide(TITLE_SHOT)
			_diorama.spotlight(-1)
			_prompts.show_prompts([])
		Screen.MENU:
			_glide(MENU_SHOT)
			_diorama.spotlight(-1)
			_menu.take_focus()
			_prompts.show_prompts([["a", "Select"], ["b", "Back"]])
		Screen.OPTIONS:
			_options.open()
			_prompts.show_prompts([])
		Screen.CLASS_SELECT:
			_choose(chosen, true)
			_prompts.show_prompts([["dpad", "Switch class"], ["a", "Choose"], ["b", "Back"]])

func _choose(index: int, quietly := false) -> void:
	chosen = wrapi(index, 0, Session.CLASSES.size())
	if not quietly:
		Sound.play("focus")
	_glide(CLASS_SHOTS[chosen])
	_diorama.spotlight(chosen)
	_class_panel.show_class(Session.CLASSES[chosen], chosen == 0)

func _enter_crypt() -> void:
	screen = Screen.LEAVING
	Session.hero_class = Session.CLASSES[chosen]
	Session.begin_new_hero()
	Sound.play("select")
	_diorama.heroes[chosen].play(Session.hero_class.chosen, 0.2, true)
	_fade(_class_panel, false)
	_prompts.show_prompts([])
	await get_tree().create_timer(1.3).timeout
	SceneManager.go_to(GAME)

func _glide(shot: Array) -> void:
	if _shot_tween:
		_shot_tween.kill()
	_shot_tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_shot_tween.tween_property(_camera, "position", shot[0], SHOT_SECONDS)
	_shot_tween.tween_property(self, "_look_at", shot[1], SHOT_SECONDS)

func _fade(control: CanvasItem, on: bool) -> void:
	if on == control.visible and is_equal_approx(control.modulate.a, 1.0 if on else 0.0):
		return
	var tween := create_tween()
	if on:
		control.modulate.a = 0.0
		control.show()
		tween.tween_property(control, "modulate:a", 1.0, 0.35)
	else:
		tween.tween_property(control, "modulate:a", 0.0, 0.25)
		tween.tween_callback(control.hide)

func _is_any_press(event: InputEvent) -> bool:
	if event.is_echo() or not event.is_pressed():
		return false
	return event is InputEventJoypadButton or event is InputEventKey or event is InputEventMouseButton \
		or event.is_action("ui_accept")

func _root_control() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)
	return root

func _centre(control: Control) -> void:
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_child(control)
	_ui.add_child(centre)

# The logo up top and the press-to-begin prompt at the bottom, in one full-screen layer that fades as one
func _build_title() -> void:
	_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_title)
	var top := VBoxContainer.new()
	_title.add_child(top)
	top.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_KEEP_SIZE, 120)
	top.grow_horizontal = Control.GROW_DIRECTION_BOTH
	top.add_theme_constant_override("separation", 6)
	var logo := UiTheme.heading("Ember Crypt", 150, UiTheme.GOLD)
	logo.add_theme_color_override("font_shadow_color", Color(UiTheme.EMBER, 0.55))
	logo.add_theme_constant_override("shadow_outline_size", 28)
	logo.add_theme_constant_override("shadow_offset_y", 0)
	top.add_child(logo)
	top.add_child(UiTheme.divider(560))
	top.add_child(UiTheme.heading("The dead do not rest here", 30, UiTheme.FADED))
	var press := PromptBar.new()
	press.alignment = BoxContainer.ALIGNMENT_CENTER
	press.show_prompts([["a", "Press to begin"]])
	_title.add_child(press)
	press.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_KEEP_SIZE, 150)
	press.grow_horizontal = Control.GROW_DIRECTION_BOTH
	press.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_press_start = press

# The menu down the left, over a shadow that darkens that side of the room so the words read
func _build_menu() -> void:
	_menu_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_menu_layer)
	var shade := TextureRect.new()
	var fade := Gradient.new()
	fade.set_color(0, Color(UiTheme.VOID, 0.92))
	fade.add_point(0.55, Color(UiTheme.VOID, 0.75))
	fade.set_color(fade.get_point_count() - 1, Color(UiTheme.VOID, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = fade
	texture.width = 256
	texture.height = 4
	shade.texture = texture
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	shade.custom_minimum_size.x = 1000
	_menu_layer.add_child(shade)
	_menu_layer.add_child(_menu_box)
	_menu_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT, Control.PRESET_MODE_KEEP_SIZE, 140)
	_menu_box.grow_vertical = Control.GROW_DIRECTION_BOTH
	_menu_box.add_theme_constant_override("separation", 14)
	_menu_box.custom_minimum_size.x = 520
	_menu_box.add_child(UiTheme.heading("Ember Crypt", 64, UiTheme.GOLD))
	_menu_box.add_child(UiTheme.divider(440))
	_menu.add_item("Continue", func() -> void: pass, false)
	_menu.add_item("New Game", func() -> void: _show(Screen.CLASS_SELECT))
	_menu.add_item("Options", func() -> void: _show(Screen.OPTIONS))
	_menu.add_item("Quit", func() -> void: get_tree().quit())
	_menu_box.add_child(_menu)
	_menu_layer.hide()
