extends Node
# One-shot UI and combat sounds on the Sounds bus: the WAVs Compositions renders, and the recorded Foley
# sets. A synth sound brings its Foley underlay with it. A small pool of players lets sounds overlap; a
# burst bigger than the pool cuts off the oldest.

const POOL_SIZE := 24

# Every synth sound and Foley set as it starts, by name
signal played(sound_name: String)

var _sounds := {}
var _foley := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for name: String in Compositions.SOUNDS:
		_sounds[name] = load(Compositions.SOUNDS_DIR + name + ".wav")
	for set_name: String in Foley.SETS:
		_foley[set_name] = Foley.load_set(set_name)
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = &"Sounds"
		add_child(player)
		_players.append(player)

# Plays a synth sound (and its underlay, if it has one) or a Foley set by name
func play(name: String, pitch := 1.0, volume_db := 0.0) -> void:
	if _sounds.has(name):
		_start(_sounds[name], pitch, volume_db)
		played.emit(name)
		if Foley.UNDERLAYS.has(name):
			play_foley(Foley.UNDERLAYS[name], pitch, volume_db)
	elif _foley.has(name):
		play_foley(name, pitch, volume_db)
	else:
		push_error("No sound called %s" % name)

# A random take from a Foley set, at the set's level
func play_foley(set_name: String, pitch := 1.0, volume_db := 0.0) -> void:
	var takes: Array[AudioStream] = _foley[set_name]
	if takes.is_empty():
		return
	_start(takes.pick_random(), pitch, volume_db + Foley.SETS[set_name])
	played.emit(set_name)

func _start(stream: AudioStream, pitch: float, volume_db: float) -> void:
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.play()
