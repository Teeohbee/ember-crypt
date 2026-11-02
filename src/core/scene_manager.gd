extends CanvasLayer
# Every screen change goes through here: fade to black, swap, fade back in. Input is off and the old
# scene is frozen while it happens, so a double press changes scene once. It also installs the UI
# theme, since every screen passes through it.

signal scene_revealed

const FADE_OUT := 0.45
const FADE_IN := 0.7

var is_changing := false
# Always 1 in the game; tests turn it up
var speed_scale := 1.0

var _cover := ColorRect.new()

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiTheme.install()
	_cover.color = Color(UiTheme.VOID, 0.0)
	_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_cover)

# Returns false if a change is already under way, so double presses are harmless.
func go_to(scene_path: String) -> bool:
	if is_changing:
		return false
	is_changing = true
	_change(scene_path)
	return true

# Fades up from black: for the first scene, which nothing faded out of.
func reveal() -> void:
	_cover.color.a = 1.0
	await _fade_to(0.0, FADE_IN, Tween.EASE_OUT)
	scene_revealed.emit()

func _change(scene_path: String) -> void:
	get_viewport().set_disable_input(true)
	_freeze(get_tree().current_scene)
	Music.fade_out(FADE_OUT / speed_scale)
	await _fade_to(1.0, FADE_OUT, Tween.EASE_IN)
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)
	await get_tree().scene_changed
	await _fade_to(0.0, FADE_IN, Tween.EASE_OUT)
	get_viewport().set_disable_input(false)
	is_changing = false
	scene_revealed.emit()

func _fade_to(alpha: float, seconds: float, easing: Tween.EaseType) -> void:
	var tween := create_tween().set_ignore_time_scale(true).set_speed_scale(speed_scale)
	tween.tween_property(_cover, "color:a", alpha, seconds).set_trans(Tween.TRANS_SINE).set_ease(easing)
	await tween.finished

func _freeze(scene: Node) -> void:
	if scene != null:
		scene.process_mode = Node.PROCESS_MODE_DISABLED
