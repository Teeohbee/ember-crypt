class_name PauseMenu
extends CanvasLayer
# Start pauses: the world blurs and darkens behind a column of choices, and the music drops under
# it. Start or B resumes. Leaving for the main menu or the desktop asks first, defaulting to stay.

const FRONT_END := "res://src/frontend/front_end.tscn"
const BLUR_SHADER := """
shader_type canvas_item;
uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap;
uniform float amount : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec3 blurred = textureLod(screen, SCREEN_UV, amount * 3.0).rgb;
	COLOR = vec4(mix(blurred, blurred * vec3(0.32, 0.27, 0.25), amount), 1.0);
}
"""

var is_open := false

var _backdrop := ColorRect.new()
var _column := VBoxContainer.new()
var _menu := MenuList.new()
var _options := OptionsMenu.new()
var _confirm := ConfirmBox.new()
var _prompts: PromptBar
var _tween: Tween

func _init() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	var material := ShaderMaterial.new()
	material.shader = Shader.new()
	material.shader.code = BLUR_SHADER
	_backdrop.material = material
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_backdrop)
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	_column.add_theme_constant_override("separation", 14)
	centre.add_child(_column)
	_column.add_child(UiTheme.heading("Paused", 72))
	_column.add_child(UiTheme.divider(420))
	_menu.add_item("Resume", close)
	_menu.add_item("Options", func() -> void:
		_column.hide()
		_options.open())
	_menu.add_item("Main Menu", func() -> void:
		_ask("Return to the main menu?", func() -> void: SceneManager.go_to(FRONT_END)))
	_menu.add_item("Quit Game", func() -> void:
		_ask("Quit to the desktop?", func() -> void: get_tree().quit()))
	_column.add_child(_menu)
	centre.add_child(_options)
	_options.hide()
	_options.closed.connect(_back_to_menu)
	centre.add_child(_confirm)
	_confirm.hide()
	_confirm.answered.connect(func(_leave: bool) -> void: _back_to_menu())
	var corner := Control.new()
	corner.set_anchors_preset(Control.PRESET_FULL_RECT)
	corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(corner)
	_prompts = PromptBar.in_corner(corner)
	_prompts.show_prompts([["a", "Select"], ["b", "Resume"]])
	_set_shown(0.0)
	hide()

# Leaving for the main menu from here would otherwise take the ducked music with it
func _exit_tree() -> void:
	if is_open:
		Music.duck(false)

func _unhandled_input(event: InputEvent) -> void:
	if SceneManager.is_changing:
		return
	if not is_open:
		if event.is_action_pressed("pause"):
			get_viewport().set_input_as_handled()
			open()
	elif _column.visible and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		close()

func open() -> void:
	is_open = true
	get_tree().paused = true
	Music.duck(true)
	Sound.play("open")
	show()
	_menu.reset()
	_back_to_menu()
	_animate(1.0)

func close() -> void:
	is_open = false
	Sound.play("back")
	Music.duck(false)
	get_tree().paused = false
	_animate(0.0).tween_callback(hide)

func _back_to_menu() -> void:
	_column.show()
	_menu.take_focus()

func _ask(question: String, on_yes: Callable) -> void:
	_column.hide()
	_confirm.ask(question, on_yes)

func _animate(to: float) -> Tween:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_ignore_time_scale(true)
	_tween.tween_method(_set_shown, _backdrop.material.get_shader_parameter("amount"), to, 0.25)
	return _tween

func _set_shown(amount: float) -> void:
	_backdrop.material.set_shader_parameter("amount", amount)
	_column.modulate.a = amount
	_prompts.modulate.a = amount
