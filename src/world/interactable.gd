class_name Interactable
extends Node3D
# Something a hero uses with A: a waypoint, the stash, the vendor, a stairway. A goes to it rather
# than the primary skill when the hero is within reach and nothing hostile is close (the plan's rule,
# which pick-ups share), so a fight never turns into an accidental shopping trip. The nearest wins.

signal used(hero: Hero)

const GROUP := &"interactables"
# Any living monster this close and A attacks instead
const SAFE_RADIUS := 6.0

# What the prompt says: "[A] Stash"
var prompt := "Use"
var reach := 2.5
var enabled := true

func _init(words := "Use", within := 2.5) -> void:
	prompt = words
	reach = within

func _enter_tree() -> void:
	add_to_group(GROUP)

func use(hero: Hero) -> void:
	used.emit(hero)

# What A would use for this hero right now, or null.
static func find_for(hero: Hero) -> Interactable:
	if hero == null or not hero.alive or not hero.is_inside_tree():
		return null
	var best: Interactable
	var best_distance := INF
	for node in hero.get_tree().get_nodes_in_group(GROUP):
		var candidate := node as Interactable
		if candidate == null or not candidate.enabled or not candidate.is_visible_in_tree():
			continue
		var distance := _flat_distance(hero.global_position, candidate.global_position)
		if distance <= candidate.reach and distance < best_distance:
			best = candidate
			best_distance = distance
	if best == null:
		return null
	for hostile in hero.hostiles():
		if _flat_distance(hero.global_position, hostile.global_position) < SAFE_RADIUS:
			return null
	return best

static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
