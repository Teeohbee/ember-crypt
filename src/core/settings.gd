extends Node
# Player settings, saved to user://settings.json. A missing or broken file never stops the game: it
# starts from the defaults and says so in the log. Only names we know are read, only of the right
# type, and numbers are clamped. Every change is applied straight away and saved.

signal changed(key: String, value: Variant)

const FORMAT_VERSION := 1

# Each setting's default, and for numbers its range. Volumes and shake are 0-10 steps.
const LIMITS := {
	"master_volume": {"default": 8, "smallest": 0, "largest": 10},
	"music_volume": {"default": 7, "smallest": 0, "largest": 10},
	"sound_volume": {"default": 8, "smallest": 0, "largest": 10},
	"fullscreen": {"default": true},
	"vsync": {"default": true},
	"show_fps": {"default": false},
	"screen_shake": {"default": 7, "smallest": 0, "largest": 10},
	"rumble": {"default": true},
}

const VOLUME_BUSES := {"master_volume": "Master", "music_volume": "Music", "sound_volume": "Sounds"}

var path := "user://settings.json"
var _values := {}

func _ready() -> void:
	load_from_disk()
	for key in _values:
		# The game launches fullscreen already; only a saved "off" changes that, so --windowed and the
		# editor's embedded game window are left alone
		if key != "fullscreen" or not _values.fullscreen:
			_apply(key)

func get_value(key: String) -> Variant:
	return _values[key]

func set_value(key: String, value: Variant) -> void:
	_values[key] = _limited(key, value)
	save_to_disk()
	_apply(key)
	changed.emit(key, _values[key])

func is_toggle(key: String) -> bool:
	return LIMITS[key].default is bool

func load_from_disk() -> void:
	_values = {}
	for key in LIMITS:
		_values[key] = LIMITS[key].default
	if not FileAccess.file_exists(path):
		return
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or not parser.data is Dictionary:
		push_warning("Settings file %s couldn't be read, starting from defaults" % path)
		return
	var saved: Variant = parser.data.get("settings", {})
	if not saved is Dictionary:
		return
	for key in _values:
		var value: Variant = saved.get(key)
		if is_toggle(key) and value is bool:
			_values[key] = value
		elif not is_toggle(key) and (value is int or value is float):
			_values[key] = _limited(key, int(value))

func save_to_disk() -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Couldn't write settings file %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return
	file.store_string(JSON.stringify({"version": FORMAT_VERSION, "settings": _values}, "\t"))

func _limited(key: String, value: Variant) -> Variant:
	var limits: Dictionary = LIMITS[key]
	if limits.has("largest"):
		return clampi(value, limits.smallest, limits.largest)
	return value

func _apply(key: String) -> void:
	if VOLUME_BUSES.has(key):
		var bus := AudioServer.get_bus_index(VOLUME_BUSES[key])
		AudioServer.set_bus_mute(bus, _values[key] == 0)
		AudioServer.set_bus_volume_db(bus, linear_to_db(_values[key] / 10.0))
	elif key == "fullscreen":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if _values.fullscreen else DisplayServer.WINDOW_MODE_MAXIMIZED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)
	elif key == "vsync":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if _values.vsync else DisplayServer.VSYNC_DISABLED)
