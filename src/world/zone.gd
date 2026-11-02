class_name Zone
extends Node3D
# A place: its geometry, lights and where things start. Game builds one, drops the heroes at
# hero_start and wakes its SpawnPoints. Subclasses build themselves in build(); id is what
# Session.zone_id and ZoneLibrary know it by.

var id := ""
var display_name := ""
var music := "crypt"
var hero_start := Vector3.ZERO

# Override: lay out floors, walls, props, lights, SpawnPoints and Checkpoints
func build() -> void:
	pass

func spawn_points() -> Array[SpawnPoint]:
	var found: Array[SpawnPoint] = []
	for node in find_children("*", "SpawnPoint", true, false):
		found.append(node)
	return found

# Spawns every SpawnPoint's monsters
func populate() -> void:
	for point in spawn_points():
		point.spawn()
