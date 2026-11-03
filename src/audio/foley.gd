class_name Foley
# Recorded sounds (CC0, from Kenney and OpenGameArt) to sit alongside the synthesised ones. Each set is a
# folder of takes in assets/audio/foley/; playing a set picks a take at random, so a sound heard fifty
# times a fight doesn't machine-gun.
#
# The synth stays the voice of the game. Most sets are underlays: whenever a synth sound plays, the set
# UNDERLAYS names plays with it, so call sites don't change. A few sets are played on their own by name
# (footsteps, a pack waking).

const FOLEY_DIR := "res://assets/audio/foley/"

# Set name: volume in dB, levelled by ear-and-meter to sit just under the synth (which averages ~-22 dB)
const SETS := {
	"hit": -9.0,
	"hit_heavy": -8.0,
	"hero_struck": 0.0,
	"wood_smash": -6.0,
	"pumpkin_squash": -8.0,
	"ground_slam": -5.0,
	"footstep_stone": -11.0,
	"footstep_grass": -2.0,
	"coins": 2.0,
	"leather": 8.0,
	"cloth": -1.0,
	"chest_creak": -2.0,
	"bone_rattle": -2.0,
	"skeleton_wake": -4.0,
	"beast_roar": -5.0,
}

# Synth sound: the foley set that plays under it
const UNDERLAYS := {
	"impact": "hit",
	"impact_crit": "hit_heavy",
	"hurt": "hero_struck",
	"smash": "wood_smash",
	"squelch": "pumpkin_squash",
	"leap_land": "ground_slam",
	"boss_slam": "ground_slam",
	"bones": "bone_rattle",
	"pickup_gold": "coins",
	"gold": "coins",
	"coins": "coins",
	"pickup": "leather",
	"equip": "cloth",
	"stash": "chest_creak",
	"boss_roar": "beast_roar",
}

# Sets a hero's feet use, by zone id; anywhere else is stone
const FOOTSTEPS := {"graveyard": "footstep_grass"}

static func footsteps_for(zone_id: String) -> String:
	return FOOTSTEPS.get(zone_id, "footstep_stone")

# Every take in a set, loaded
static func load_set(set_name: String) -> Array[AudioStream]:
	var takes: Array[AudioStream] = []
	var folder := FOLEY_DIR + set_name + "/"
	for file in ResourceLoader.list_directory(folder):
		if file.ends_with(".ogg") or file.ends_with(".wav"):
			takes.append(load(folder + file))
	return takes
