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
# Zones the heroes have found a waypoint in; the town's is always known
var waypoints: Array[String] = ["town"]
# The town stash: one chest shared by every hero (M5 saves it)
var stash := Inventory.new(60)
# What each slot's hero carries between zones, by slot index (see Travel)
var carried := {}
# Where heroes come into the next zone: "waypoint", "gate", "stairs"; empty is the zone's default
var arrival := ""

# Sets the world up for a character: the waypoints they've found and their crypt, nothing carried
func enter_world(known_waypoints: Array, crypt_seed: int) -> void:
	waypoints.assign(known_waypoints if not known_waypoints.is_empty() else ["town"])
	dungeon_seed = crypt_seed
	carried = {}
	arrival = ""
