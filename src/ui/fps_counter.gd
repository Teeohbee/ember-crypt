extends CanvasLayer
# The frame rate in the top-right corner, when Show frame rate is on. Updates twice a second so the
# number is readable rather than a blur.

var _label := UiTheme.text("", 24, UiTheme.FADED)
var _wait := 0.0

func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_label)
	_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_KEEP_SIZE, 20)
	_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	visible = Settings.get_value("show_fps")
	Settings.changed.connect(func(key: String, value: Variant) -> void:
		if key == "show_fps":
			visible = value)

func _process(delta: float) -> void:
	_wait -= delta
	if visible and _wait <= 0.0:
		_wait = 0.5
		_label.text = "%d fps" % Engine.get_frames_per_second()
