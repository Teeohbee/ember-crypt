class_name InteractPrompt
extends HBoxContainer
# "[A] Stash" low in the middle of the screen whenever A would use something rather than swing. It
# looks a few times a second, not every frame; nobody notices a tenth of a second here.

const LOOK_EVERY := 0.1

var hud: Hud
var showing: Interactable
var _words := UiTheme.text("", 30, UiTheme.PARCHMENT)
var _wait := 0.0
var _tween: Tween

func _init(owner_hud: Hud) -> void:
	hud = owner_hud
	name = "InteractPrompt"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 12)
	add_child(ButtonGlyph.new("a", 38))
	add_child(_words)
	modulate.a = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_KEEP_SIZE, 300)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BEGIN

func _process(delta: float) -> void:
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = LOOK_EVERY
	refresh()

func refresh() -> void:
	var found := Interactable.find_for(hud.hero())
	if found == showing and (found == null or _words.text == found.prompt):
		return
	showing = found
	if found:
		_words.text = found.prompt
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0 if found else 0.0, 0.15)
