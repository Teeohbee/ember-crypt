extends Node
# What this run of the game is playing: the hero picked on class select, the players, where they'll
# come back to life. Becomes the save slot in M5.

const CLASSES: Array[HeroClass] = [
	preload("res://src/hero/classes/barbarian.tres"),
	preload("res://src/hero/classes/mage.tres"),
]

var hero_class: HeroClass = CLASSES[0]
# One slot until co-op; every hero belongs to one
var slots: Array[PlayerSlot] = [PlayerSlot.new(0)]
# Which zone Game builds; empty means the test room
var zone_id := ""
# Where a dead hero comes back, set by the last Checkpoint touched. Vector3.INF means the zone's start.
var checkpoint := Vector3.INF

func heroes() -> Array[Hero]:
	var all: Array[Hero] = []
	for slot in slots:
		if is_instance_valid(slot.hero):
			all.append(slot.hero)
	return all

# M6 World
# The crypt's layout seed; 0 until it's first entered, then the same crypt every visit
var dungeon_seed := 0
