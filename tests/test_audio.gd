extends GdUnitTestSuite
# Every sound the game asks for has been rendered, music loops, and both buses feed Master so the
# volume settings do what they say.

func test_every_composition_has_been_rendered() -> void:
	for name in Compositions.SOUNDS:
		assert_bool(ResourceLoader.exists(Compositions.SOUNDS_DIR + name + ".wav")).override_failure_message(
			"%s.wav is missing: run tools/render_audio.gd" % name).is_true()
	for name in Compositions.MUSIC:
		assert_bool(ResourceLoader.exists(Compositions.MUSIC_DIR + name + ".wav")).override_failure_message(
			"%s.wav is missing: run tools/render_audio.gd" % name).is_true()

func test_music_loops() -> void:
	for name in Compositions.MUSIC:
		var stream: AudioStreamWAV = Music._streams[name]
		assert_int(stream.loop_mode).is_equal(AudioStreamWAV.LOOP_FORWARD)

func test_music_and_sounds_feed_master() -> void:
	for bus in ["Music", "Sounds"]:
		var index := AudioServer.get_bus_index(bus)
		assert_int(index).is_not_equal(-1)
		assert_str(AudioServer.get_bus_send(index)).is_equal("Master")
