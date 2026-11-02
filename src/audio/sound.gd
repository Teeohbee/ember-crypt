extends Node
# One-shot UI sounds on the Sounds bus, from the WAVs Compositions renders. A small pool of players
# lets sounds overlap; a burst bigger than the pool cuts off the oldest.

const POOL_SIZE := 8

var _sounds := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for name: String in Compositions.SOUNDS:
		_sounds[name] = load(Compositions.SOUNDS_DIR + name + ".wav")
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = &"Sounds"
		add_child(player)
		_players.append(player)

func play(name: String, pitch := 1.0, volume_db := 0.0) -> void:
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = _sounds[name]
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.play()
