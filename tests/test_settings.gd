extends ScreenSuite
# Settings: a missing or broken file gives the defaults, only known settings of the right type load,
# numbers stay in range, and changes are saved and drive the audio buses.

func _write(contents: String) -> void:
	var file := FileAccess.open(scratch_path, FileAccess.WRITE)
	file.store_string(contents)
	file.close()
	Settings.load_from_disk()

func _bus_db(bus: String) -> float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus))

func test_a_missing_file_gives_the_defaults() -> void:
	for key in Settings.LIMITS:
		assert_that(Settings.get_value(key)).is_equal(Settings.LIMITS[key].default)

func test_a_broken_file_gives_the_defaults() -> void:
	_write("{ not json")
	assert_int(Settings.get_value("music_volume")).is_equal(Settings.LIMITS.music_volume.default)

func test_only_known_settings_of_the_right_type_load() -> void:
	_write(JSON.stringify({"settings": {"music_volume": 3, "rumble": "yes please", "cheat_mode": true}}))
	assert_int(Settings.get_value("music_volume")).is_equal(3)
	assert_bool(Settings.get_value("rumble")).is_true()

func test_numbers_stay_in_range() -> void:
	Settings.set_value("sound_volume", 14)
	assert_int(Settings.get_value("sound_volume")).is_equal(10)
	Settings.set_value("sound_volume", -2)
	assert_int(Settings.get_value("sound_volume")).is_equal(0)

func test_changes_survive_a_reload() -> void:
	Settings.set_value("screen_shake", 2)
	Settings.set_value("rumble", false)
	Settings.load_from_disk()
	assert_int(Settings.get_value("screen_shake")).is_equal(2)
	assert_bool(Settings.get_value("rumble")).is_false()

func test_volumes_drive_their_buses() -> void:
	Settings.set_value("music_volume", 5)
	assert_float(_bus_db("Music")).is_equal_approx(linear_to_db(0.5), 0.01)
	Settings.set_value("sound_volume", 0)
	assert_bool(AudioServer.is_bus_mute(AudioServer.get_bus_index("Sounds"))).is_true()
