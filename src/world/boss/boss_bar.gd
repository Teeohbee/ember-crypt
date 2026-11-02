class_name BossBar
extends Control
# The boss's name and a long health bar across the top of the screen, from the moment it roars until
# it falls. Notches mark where its phases begin; the bar flashes as it crosses one. On its death the
# name gives way to "Slain" and the bar fades.

const WIDTH := 900.0
const BAR_HEIGHT := 22.0
const FILL := Color("9c2a1e")
const DRAIN := Color("e3b45a")

var slot: PlayerSlot
var boss: Monster
var fraction := 1.0
var _shown := 1.0
var _flash := 0.0
var _title := UiTheme.heading("", 40, UiTheme.PARCHMENT)

func _init(player_slot: PlayerSlot) -> void:
	slot = player_slot
	name = "BossBar"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(WIDTH, 90)
	_title.position = Vector2(0, 0)
	_title.size = Vector2(WIDTH, 50)
	add_child(_title)
	modulate.a = 0.0
	hide()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_KEEP_SIZE, 40)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	Events.boss_engaged.connect(watch)
	Events.boss_phase_changed.connect(_on_phase)

func _exit_tree() -> void:
	Events.boss_engaged.disconnect(watch)
	Events.boss_phase_changed.disconnect(_on_phase)

func watch(engaged: Monster) -> void:
	if boss == engaged:
		return
	boss = engaged
	_title.text = engaged.def.display_name
	fraction = engaged.health / engaged.max_health()
	_shown = fraction
	engaged.health_changed.connect(func(health: float, max_health: float) -> void:
		fraction = health / max_health)
	engaged.died.connect(func(_event: DamageEvent) -> void: _slain())
	show()
	create_tween().tween_property(self, "modulate:a", 1.0, 0.6)

func _on_phase(phased: Monster, _phase: int) -> void:
	if phased == boss:
		_flash = 1.0

func _slain() -> void:
	_title.text = "Slain"
	_title.add_theme_color_override("font_color", UiTheme.GOLD)
	var tween := create_tween()
	tween.tween_interval(2.5)
	tween.tween_property(self, "modulate:a", 0.0, 1.5)
	tween.tween_callback(hide)

func _process(delta: float) -> void:
	if not visible:
		return
	# The gold drain trails the red, so a big hit reads as a big hit
	_shown = move_toward(_shown, fraction, delta * 0.5) if _shown > fraction else fraction
	_flash = maxf(_flash - delta * 2.0, 0.0)
	queue_redraw()

func _draw() -> void:
	var top := 52.0
	var frame := Rect2(0, top, WIDTH, BAR_HEIGHT)
	draw_rect(frame.grow(3), UiTheme.BRONZE)
	draw_rect(frame, Color(UiTheme.VOID, 0.92))
	draw_rect(Rect2(0, top, WIDTH * _shown, BAR_HEIGHT), DRAIN)
	draw_rect(Rect2(0, top, WIDTH * fraction, BAR_HEIGHT), FILL.lerp(Color.WHITE, _flash * 0.6))
	for i in range(1, BossBrain.PHASES.size()):
		var x: float = WIDTH * BossBrain.PHASES[i]
		draw_line(Vector2(x, top - 4), Vector2(x, top + BAR_HEIGHT + 4), UiTheme.GOLD, 2.0)
