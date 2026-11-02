class_name Compositions
extends RefCounted
# Everything the synth makes, by name. tools/render_audio.gd writes each to assets/audio/ as a WAV;
# change a recipe here, rerun the tool, commit both.
#
# Music is in D harmonic minor, which is where a lot of gothic organ music lives: the major chord on
# the fifth (A, with its C#) pulls hard back to D minor.

const MUSIC_DIR := "res://assets/audio/music/"
const SOUNDS_DIR := "res://assets/audio/ui/"

# UI sounds: [length, [[start, MIDI note, length, voice, volume], ...]]
const SOUNDS := {
	"focus": [0.12, [[0.0, 57, 0.12, "thud", 0.5], [0.0, 81, 0.08, "pluck", 0.08]]],
	"confirm": [1.6, [[0.0, 62, 1.6, "bell", 0.3], [0.05, 69, 1.5, "bell", 0.22], [0.0, 38, 0.3, "thud", 0.4]]],
	"back": [1.0, [[0.0, 69, 1.0, "bell", 0.22], [0.08, 62, 0.9, "bell", 0.22]]],
	"tick": [0.08, [[0.0, 74, 0.08, "pluck", 0.25]]],
	"open": [1.0, [[0.0, 50, 1.0, "bell", 0.18], [0.0, 38, 0.3, "thud", 0.5]]],
	"denied": [0.25, [[0.0, 45, 0.2, "thud", 0.6], [0.09, 44, 0.16, "thud", 0.5]]],
	"select": [3.5, [[0.0, 50, 3.5, "toll", 0.45], [0.0, 62, 2.0, "bell", 0.15], [0.0, 69, 2.0, "bell", 0.1]]],
	# M1 Feel: combat. For "crunch" and "whoosh" the note is brightness, not pitch.
	"swing": [0.34, [[0.0, 78, 0.32, "whoosh", 0.55]]],
	"impact": [0.35, [[0.0, 40, 0.3, "thud", 0.38], [0.0, 70, 0.14, "crunch", 0.25], [0.0, 31, 0.25, "thud", 0.22]]],
	"impact_crit": [0.7, [[0.0, 36, 0.35, "thud", 0.42], [0.0, 80, 0.2, "crunch", 0.28], [0.02, 74, 0.6, "bell", 0.12], [0.0, 28, 0.3, "thud", 0.22]]],
	"bones": [0.6, [[0.0, 96, 0.1, "crunch", 0.4], [0.03, 79, 0.08, "thud", 0.35], [0.08, 84, 0.08, "thud", 0.3],
		[0.13, 76, 0.08, "thud", 0.3], [0.2, 88, 0.08, "thud", 0.22], [0.27, 81, 0.08, "thud", 0.18], [0.36, 77, 0.08, "thud", 0.12],
		[0.15, 104, 0.08, "crunch", 0.2]]],
	"missile": [0.45, [[0.0, 112, 0.34, "whoosh", 0.3], [0.0, 81, 0.42, "bell", 0.1], [0.03, 88, 0.38, "bell", 0.07]]],
	"missile_hit": [0.55, [[0.0, 118, 0.16, "crunch", 0.4], [0.0, 76, 0.5, "bell", 0.13], [0.0, 45, 0.2, "thud", 0.45]]],
	"roll": [0.42, [[0.0, 52, 0.38, "whoosh", 0.5], [0.3, 40, 0.1, "thud", 0.25]]],
	"hurt": [0.35, [[0.0, 34, 0.3, "thud", 0.6], [0.0, 50, 0.14, "crunch", 0.3]]],
	# M2 Combat kit
	"potion": [1.3, [[0.0, 55, 0.1, "thud", 0.5], [0.08, 58, 0.1, "thud", 0.45], [0.16, 62, 0.1, "thud", 0.4],
		[0.25, 74, 1.0, "bell", 0.2], [0.3, 81, 0.9, "bell", 0.12]]],
	"cleave": [0.5, [[0.0, 60, 0.3, "hiss", 0.5], [0.12, 40, 0.25, "thud", 0.7]]],
	"leap": [0.4, [[0.0, 64, 0.35, "hiss", 0.35]]],
	"leap_land": [1.4, [[0.0, 28, 0.6, "thud", 1.0], [0.0, 33, 1.2, "toll", 0.25], [0.0, 50, 0.5, "hiss", 0.4]]],
	"war_cry": [1.8, [[0.0, 45, 1.6, "toll", 0.45], [0.0, 57, 1.2, "bell", 0.2], [0.05, 64, 1.2, "bell", 0.15],
		[0.0, 33, 0.4, "thud", 0.6]]],
	"frost_nova": [1.2, [[0.0, 60, 0.6, "hiss", 0.35], [0.0, 86, 1.0, "bell", 0.15], [0.04, 89, 0.9, "bell", 0.12],
		[0.08, 93, 0.8, "bell", 0.1], [0.0, 45, 0.3, "thud", 0.5]]],
	"arcane_orb": [0.9, [[0.0, 74, 0.7, "bell", 0.2], [0.03, 79, 0.6, "bell", 0.14], [0.0, 66, 0.3, "hiss", 0.25]]],
	"orb_burst": [1.2, [[0.0, 30, 0.6, "thud", 0.9], [0.0, 57, 1.0, "toll", 0.25], [0.0, 70, 0.5, "hiss", 0.5],
		[0.0, 81, 0.8, "bell", 0.12]]],
	"teleport": [0.8, [[0.0, 90, 0.25, "hiss", 0.3], [0.0, 81, 0.5, "bell", 0.15], [0.06, 74, 0.5, "bell", 0.15],
		[0.12, 86, 0.5, "bell", 0.1]]],
	# M3 Monsters
	# A big attack winding up: a knock and a sour minor second
	"telegraph": [0.6, [[0.0, 45, 0.5, "thud", 0.6], [0.0, 57, 0.45, "pluck", 0.3], [0.1, 58, 0.45, "bell", 0.16]]],
	# Bones clawing out of the floor: a sub swell under a slow, crooked chord
	"summon": [2.0, [[0.0, 38, 2.0, "sub", 0.5], [0.0, 61, 1.8, "bell", 0.15], [0.15, 62, 1.7, "bell", 0.12], [0.3, 68, 1.5, "bell", 0.1]]],
	"quarrel": [0.3, [[0.0, 64, 0.25, "pluck", 0.5], [0.0, 40, 0.15, "thud", 0.45]]],
	"witchfire": [0.7, [[0.0, 73, 0.6, "bell", 0.16], [0.03, 80, 0.5, "bell", 0.1], [0.0, 49, 0.3, "thud", 0.3]]],
	# An elite pack: a toll a tritone off the key
	"elite": [2.2, [[0.0, 39, 2.2, "toll", 0.4], [0.0, 51, 1.5, "bell", 0.15], [0.1, 57, 1.4, "bell", 0.12]]],
	"shield": [0.8, [[0.0, 74, 0.8, "bell", 0.18], [0.05, 81, 0.7, "bell", 0.12], [0.0, 50, 0.3, "thud", 0.3]]],
	"molten": [0.5, [[0.0, 40, 0.3, "thud", 0.6], [0.05, 34, 0.4, "thud", 0.5]]],
	# Death: the big bell, low, on D minor. Coming back: D major rising, the only major chord in the game
	"hero_death": [4.0, [[0.0, 26, 4.0, "toll", 0.55], [0.0, 38, 3.0, "toll", 0.35], [0.0, 50, 2.5, "bell", 0.12], [0.0, 53, 2.5, "bell", 0.1]]],
	"respawn": [2.5, [[0.0, 62, 2.0, "bell", 0.22], [0.12, 66, 2.0, "bell", 0.2], [0.24, 69, 2.1, "bell", 0.2], [0.36, 74, 2.0, "bell", 0.18], [0.0, 38, 0.5, "thud", 0.4]]],
	# M4 Loot
	# Drops land with a sound that says how rare they are before you read the name: a dull knock for
	# normal, a bell for magic, a high shimmer for rare, a toll and a rising D minor peal for legendary.
	"drop": [0.3, [[0.0, 45, 0.25, "thud", 0.6], [0.02, 69, 0.12, "pluck", 0.12]]],
	"drop_magic": [1.2, [[0.0, 45, 0.25, "thud", 0.5], [0.02, 81, 1.1, "bell", 0.2]]],
	"drop_rare": [1.8, [[0.0, 45, 0.25, "thud", 0.5], [0.02, 86, 1.6, "bell", 0.18], [0.1, 93, 1.4, "bell", 0.12], [0.2, 98, 1.2, "bell", 0.08]]],
	"drop_legendary": [4.0, [[0.0, 38, 4.0, "toll", 0.45], [0.0, 26, 1.5, "sub", 0.3], [0.15, 74, 2.5, "bell", 0.16],
		[0.3, 77, 2.5, "bell", 0.16], [0.45, 81, 2.5, "bell", 0.16], [0.6, 86, 2.5, "bell", 0.18]]],
	"gold": [0.5, [[0.0, 88, 0.2, "pluck", 0.3], [0.05, 93, 0.2, "pluck", 0.25], [0.11, 91, 0.2, "pluck", 0.22], [0.18, 96, 0.2, "pluck", 0.18]]],
	"pickup_gold": [0.35, [[0.0, 91, 0.2, "pluck", 0.28], [0.06, 96, 0.25, "pluck", 0.25]]],
	"pickup": [0.4, [[0.0, 50, 0.2, "thud", 0.55], [0.03, 74, 0.3, "pluck", 0.2]]],
	"equip": [1.4, [[0.0, 41, 0.3, "thud", 0.7], [0.04, 62, 1.2, "bell", 0.2], [0.04, 74, 1.0, "bell", 0.1]]],
	# M5 Progression
	# Level up: a toll under a bell arpeggio climbing D minor to the high A, the fifth, left ringing
	"level_up": [3.5, [[0.0, 38, 3.5, "toll", 0.4], [0.0, 62, 2.2, "bell", 0.2], [0.12, 65, 2.1, "bell", 0.2],
		[0.24, 69, 2.0, "bell", 0.2], [0.36, 74, 2.0, "bell", 0.22], [0.56, 81, 2.6, "bell", 0.24], [0.56, 50, 0.3, "thud", 0.4]]],
	# A rune set into a skill: a bright little chime
	"rune": [1.0, [[0.0, 81, 0.1, "pluck", 0.2], [0.04, 74, 0.9, "bell", 0.18], [0.1, 78, 0.8, "bell", 0.12]]],
}

const MUSIC := ["title", "crypt"]

const BAR := 4.0   # seconds; 60 bpm, four beats

static func sound(name: String) -> PackedFloat32Array:
	var recipe: Array = SOUNDS[name]
	var buffer := Synth.empty_buffer(recipe[0])
	for note: Array in recipe[1]:
		Synth.add_note(buffer, note[0], note[1], note[2], note[3], note[4])
	return buffer

static func music(name: String) -> PackedFloat32Array:
	match name:
		"title":
			return title()
		"crypt":
			return crypt()
	push_error("No composition called %s" % name)
	return PackedFloat32Array()

# Title: Dm - Bb - Gm - A, two bars each. A sub drone under a slow choir, a toll on each chord, and a
# sparse bell melody that rings out over the echo. 32 seconds, looping.
static func title() -> PackedFloat32Array:
	var loop := BAR * 8
	var buffer := Synth.empty_buffer(loop + 8.0)
	var chords := [[50, 53, 57], [46, 50, 53], [43, 46, 50], [45, 49, 52]]
	var roots := [38, 34, 31, 33]
	for i in chords.size():
		var at := i * BAR * 2
		Synth.add_note(buffer, at, roots[i] - 12, BAR * 2 + 1.0, "sub", 0.32)
		for note: int in chords[i]:
			Synth.add_note(buffer, at, note, BAR * 2 + 2.5, "pad", 0.13)
		Synth.add_note(buffer, at, roots[i], 6.0, "toll", 0.22)
	# The melody: [bar, beat, MIDI note], from D harmonic minor
	var melody := [[0, 2, 74], [1, 0, 77], [1, 2, 76], [2, 2, 74], [3, 0, 70], [4, 2, 69],
		[5, 0, 74], [5, 3, 73], [6, 2, 76], [7, 0, 73], [7, 2, 69]]
	for note: Array in melody:
		Synth.add_note(buffer, note[0] * BAR + note[1] * BAR / 4.0, note[2], 3.0, "bell", 0.11)
	Synth.add_echo(buffer, 0.75, 0.38)
	Synth.add_wind(buffer, 0.0, loop + 8.0, 0.02, 0.02, 3)
	buffer = Synth.fold_tail(buffer, loop)
	Synth.normalise(buffer, 0.8)
	return buffer

# The crypt: no tune, just the room. A low drone that shifts between D and Eb, wind through the
# passages, and a distant toll now and then. 32 seconds, looping.
static func crypt() -> PackedFloat32Array:
	var loop := BAR * 8
	var buffer := Synth.empty_buffer(loop + 8.0)
	for i in 4:
		var at := i * BAR * 2
		var root := 38 if i % 2 == 0 else 39
		Synth.add_note(buffer, at, root - 12, BAR * 2 + 2.0, "sub", 0.3)
		Synth.add_note(buffer, at, root, BAR * 2 + 2.5, "pad", 0.08)
		Synth.add_note(buffer, at, root + 7, BAR * 2 + 2.5, "pad", 0.05)
	Synth.add_note(buffer, BAR * 1.5, 38, 6.0, "toll", 0.12)
	Synth.add_note(buffer, BAR * 5.25, 37, 6.0, "toll", 0.09)
	Synth.add_wind(buffer, 0.0, loop * 0.6, 0.05, 0.03, 11)
	Synth.add_wind(buffer, loop * 0.4, loop * 0.6 + 8.0, 0.05, 0.02, 12)
	Synth.add_echo(buffer, 1.1, 0.3)
	buffer = Synth.fold_tail(buffer, loop)
	Synth.normalise(buffer, 0.7)
	return buffer
