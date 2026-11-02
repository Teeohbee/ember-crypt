extends Node
# The one place music plays from. Two players on the Music bus take turns so a new track crossfades
# over the old; asking for the track already playing does nothing. duck() lowers the music under the
# pause menu. Fades ignore pause and time scale.

const CROSSFADE := 2.0
const SILENT_DB := -40.0
const DUCKED_DB := -10.0

# Each track's level in the mix
const LEVELS := {"title": -2.0, "crypt": -4.0}

var current := ""
var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _tweens := [null, null]
var _duck: AudioEffectAmplify

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for name: String in Compositions.MUSIC:
		var stream: AudioStreamWAV = load(Compositions.MUSIC_DIR + name + ".wav")
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
		_streams[name] = stream
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = &"Music"
		player.volume_db = SILENT_DB
		add_child(player)
		_players.append(player)
	_duck = AudioEffectAmplify.new()
	AudioServer.add_bus_effect(AudioServer.get_bus_index(&"Music"), _duck)

func play(name: String) -> void:
	if name == current:
		return
	current = name
	_fade(_players[_active], SILENT_DB, CROSSFADE, true)
	_active = 1 - _active
	var player := _players[_active]
	player.stream = _streams[name]
	player.volume_db = SILENT_DB
	player.play()
	_fade(player, LEVELS[name], CROSSFADE, false)

func fade_out(seconds: float) -> void:
	current = ""
	_fade(_players[_active], SILENT_DB, seconds, true)

func duck(on: bool) -> void:
	var tween := create_tween().set_ignore_time_scale(true)
	tween.tween_property(_duck, "volume_db", DUCKED_DB if on else 0.0, 0.3)

# Each player has one fade at a time, so a quick back-and-forth never leaves an old fade-out running
# on a player that's fading back in.
func _fade(player: AudioStreamPlayer, to_db: float, seconds: float, stop_after: bool) -> void:
	var index := _players.find(player)
	if _tweens[index] != null:
		_tweens[index].kill()
	if not player.playing:
		return
	var tween := create_tween().set_ignore_time_scale(true)
	tween.tween_property(player, "volume_db", to_db, seconds).set_trans(Tween.TRANS_SINE)
	if stop_after:
		tween.tween_callback(player.stop)
	_tweens[index] = tween
