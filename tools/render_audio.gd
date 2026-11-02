extends SceneTree
# Renders every Compositions recipe to a WAV under assets/audio/. Run after changing a recipe:
#   godot --headless --path . -s tools/render_audio.gd
# then import (or open the editor) and commit the WAVs.

func _init() -> void:
	for directory in [Compositions.MUSIC_DIR, Compositions.SOUNDS_DIR]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	for name: String in Compositions.SOUNDS:
		_save(Compositions.sound(name), Compositions.SOUNDS_DIR + name + ".wav")
	for name: String in Compositions.MUSIC:
		var started := Time.get_ticks_msec()
		_save(Compositions.music(name), Compositions.MUSIC_DIR + name + ".wav")
		print("%s: %.1fs to compose" % [name, (Time.get_ticks_msec() - started) / 1000.0])
	quit()

func _save(buffer: PackedFloat32Array, path: String) -> void:
	var error := Synth.to_stream(buffer).save_to_wav(path)
	if error != OK:
		push_error("Couldn't write %s: %s" % [path, error_string(error)])
	else:
		print("wrote ", path)
