class_name DamageNumbers
extends Node
# Numbers that pop off whatever was hit, Diablo-style: a quick swell, a rise with a little sideways
# drift, then a fade. A fixed pool of Label3Ds, animated here, so a hit allocates nothing; when every
# label is busy the oldest is reused.

const POOL := 32
const LIFE := 0.85
const RISE := 1.3
const POP_SECONDS := 0.12
const FONT_SIZE := 72

var labels: Array[Label3D] = []
var _ages := PackedFloat32Array()
var _starts := PackedVector3Array()
var _drifts := PackedVector3Array()
var _sizes := PackedFloat32Array()
var _next := 0
var _drift_rng := RandomNumberGenerator.new()

func _init() -> void:
	name = "DamageNumbers"
	# Numbers freeze with the game when it pauses
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var font := UiTheme.heading_font(800)
	_ages.resize(POOL)
	_starts.resize(POOL)
	_drifts.resize(POOL)
	_sizes.resize(POOL)
	for i in POOL:
		var label := Label3D.new()
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.render_priority = 10
		label.outline_render_priority = 9
		label.font = font
		label.font_size = FONT_SIZE
		label.outline_size = 14
		label.outline_modulate = Color(0.05, 0.02, 0.02, 0.9)
		label.pixel_size = 0.0085
		label.visible = false
		labels.append(label)
		add_child(label)
		_ages[i] = LIFE

func show_number(at: Vector3, text: String, colour: Color, big := false) -> Label3D:
	var i := _next
	_next = (_next + 1) % POOL
	var label := labels[i]
	label.text = text
	label.modulate = colour
	label.global_position = at
	label.visible = true
	_ages[i] = 0.0
	_starts[i] = at
	_drifts[i] = Vector3(_drift_rng.randf_range(-0.5, 0.5), 0.0, _drift_rng.randf_range(-0.2, 0.2))
	_sizes[i] = 1.5 if big else 1.0
	_place(i)
	return label

func active_count() -> int:
	var count := 0
	for label in labels:
		if label.visible:
			count += 1
	return count

func clear() -> void:
	for i in POOL:
		_ages[i] = LIFE
		labels[i].visible = false

func _process(delta: float) -> void:
	for i in POOL:
		if _ages[i] >= LIFE:
			continue
		_ages[i] += delta
		if _ages[i] >= LIFE:
			labels[i].visible = false
		else:
			_place(i)

func _place(i: int) -> void:
	var t := _ages[i] / LIFE
	var rise := 1.0 - (1.0 - t) * (1.0 - t)
	var label := labels[i]
	label.global_position = _starts[i] + _drifts[i] * t + Vector3(0, RISE * rise, 0)
	var pop := 1.0 + 0.7 * maxf(0.0, 1.0 - _ages[i] / POP_SECONDS)
	label.scale = Vector3.ONE * _sizes[i] * pop
	label.modulate.a = 1.0 - smoothstep(0.6, 1.0, t)
	label.outline_modulate.a = label.modulate.a * 0.9
