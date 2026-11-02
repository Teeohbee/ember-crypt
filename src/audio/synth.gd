class_name Synth
extends RefCounted
# A tiny synthesiser, grown from CelestialMeadow's. Builds sounds as buffers of mono samples and
# saves them as WAVs; tools/render_audio.gd runs it headless and the game only ever plays the files.

const MIX_RATE := 22050
const NOISE_VOICES := ["crunch", "whoosh"]

static func empty_buffer(seconds: float) -> PackedFloat32Array:
	var buffer := PackedFloat32Array()
	buffer.resize(int(seconds * MIX_RATE))
	return buffer

static func to_stream(buffer: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buffer.size() * 2)
	for i in buffer.size():
		bytes.encode_s16(i * 2, int(clampf(buffer[i], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.data = bytes
	return stream

static func note_frequency(midi_note: float) -> float:
	return 440.0 * pow(2.0, (midi_note - 69.0) / 12.0)

# Adds one note. Voices: "pad", "bell", "toll", "pluck", "sub", "thud", and the noise voices
# "crunch" and "whoosh", for which the note sets brightness instead of pitch (127 is brightest).
static func add_note(buffer: PackedFloat32Array, start: float, midi_note: float, length: float, voice: String, volume: float) -> void:
	if voice in NOISE_VOICES:
		add_noise(buffer, start, midi_note / 127.0, length, voice, volume)
		return
	var first := int(start * MIX_RATE)
	var frequency := note_frequency(midi_note)
	for offset in int(length * MIX_RATE):
		if first + offset >= buffer.size():
			return
		buffer[first + offset] += voice_sample(voice, frequency, float(offset) / MIX_RATE, length) * volume

static func voice_sample(voice: String, frequency: float, time: float, length: float) -> float:
	var phase := TAU * frequency * time
	var attack := minf(time / 0.004, 1.0)
	var release := clampf((length - time) / 0.08, 0.0, 1.0)
	match voice:
		"pad":
			# A slow swell of two detuned voices with a soft fifth on top: a choir in a cold room
			var swell := minf(time / 2.0, 1.0) * clampf((length - time) / 2.0, 0.0, 1.0)
			var vibrato := 1.0 + 0.002 * sin(TAU * 4.5 * time)
			return swell * (sin(phase * vibrato) + sin(phase * 1.004) + 0.3 * sin(phase * 2.0) + 0.12 * sin(phase * 3.0)) / 2.42
		"bell":
			# Inharmonic partials that die at different speeds, the high ones first
			return attack * release * (sin(phase) * exp(-time * 1.4) + 0.5 * sin(phase * 2.76) * exp(-time * 2.6)
				+ 0.25 * sin(phase * 5.4) * exp(-time * 5.0) + 0.12 * sin(phase * 8.93) * exp(-time * 9.0))
		"toll":
			# A big, dark church bell: the hum below the strike note rings longest
			return attack * release * (0.8 * sin(phase * 0.5) * exp(-time * 0.35) + sin(phase) * exp(-time * 0.7)
				+ 0.45 * sin(phase * 1.19) * exp(-time * 1.1) + 0.3 * sin(phase * 2.0) * exp(-time * 1.6)
				+ 0.15 * sin(phase * 2.97) * exp(-time * 3.0))
		"pluck":
			return attack * release * (sin(phase) + 0.3 * sin(phase * 2.0)) * exp(-time * 18.0)
		"sub":
			var fade_in := minf(time / 0.6, 1.0)
			return fade_in * release * sin(phase)
		"thud":
			# A pitch that falls as it fades: a soft knock on wood
			var falling := TAU * frequency * (time - time * time * 6.0)
			return attack * release * sin(falling) * exp(-time * 30.0)
	return 0.0

# Wind or breath: noise through a gentle low-pass, swelling in and out. Seeded so a render is repeatable.
static func add_wind(buffer: PackedFloat32Array, start: float, length: float, volume: float, brightness := 0.04, seed_value := 1) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var first := int(start * MIX_RATE)
	var smoothed := 0.0
	for offset in int(length * MIX_RATE):
		if first + offset >= buffer.size():
			return
		var time := float(offset) / MIX_RATE
		smoothed += (rng.randf_range(-1.0, 1.0) - smoothed) * brightness
		var swell := sin(PI * time / length)
		buffer[first + offset] += smoothed * swell * swell * volume * 6.0

# Noise through a one-pole low-pass. "crunch" is a hard knock that dies fast: bone, wood, a blade
# biting. "whoosh" swells and brightens through the middle, like something swung past the ear. Seeded
# by its start and brightness, so a render is repeatable.
static func add_noise(buffer: PackedFloat32Array, start: float, brightness: float, length: float, voice: String, volume: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([start, brightness, voice])
	var first := int(start * MIX_RATE)
	var smoothed := 0.0
	for offset in int(length * MIX_RATE):
		if first + offset >= buffer.size():
			return
		var time := float(offset) / MIX_RATE
		var envelope := 0.0
		var cutoff := brightness
		if voice == "crunch":
			envelope = minf(time / 0.002, 1.0) * exp(-time * 28.0)
		else:
			var swell := sin(PI * time / length)
			envelope = swell * swell
			cutoff = brightness * (0.25 + 0.75 * swell)
		smoothed += (rng.randf_range(-1.0, 1.0) - smoothed) * clampf(cutoff * cutoff, 0.005, 1.0)
		buffer[first + offset] += smoothed * envelope * volume * (1.0 + (1.0 - cutoff) * 3.0)

# A feedback echo, in place: each repeat comes back quieter.
static func add_echo(buffer: PackedFloat32Array, delay: float, feedback: float) -> void:
	var gap := int(delay * MIX_RATE)
	for i in range(gap, buffer.size()):
		buffer[i] += buffer[i - gap] * feedback

# For loops: whatever rang past `loop_seconds` is folded back onto the start, so the seam is silent.
static func fold_tail(buffer: PackedFloat32Array, loop_seconds: float) -> PackedFloat32Array:
	var loop_length := int(loop_seconds * MIX_RATE)
	for i in range(loop_length, buffer.size()):
		buffer[i - loop_length] += buffer[i]
	return buffer.slice(0, loop_length)

static func normalise(buffer: PackedFloat32Array, peak := 0.9) -> void:
	var loudest := 0.0
	for sample in buffer:
		loudest = maxf(loudest, absf(sample))
	if loudest > 0.0:
		for i in buffer.size():
			buffer[i] *= peak / loudest
