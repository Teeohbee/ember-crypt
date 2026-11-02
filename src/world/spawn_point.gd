class_name SpawnPoint
extends Marker3D
# Where a pack of monsters starts. Zones place these; spawn() brings the pack in, scattered around the
# point, and ties them together so waking one wakes them all. A pack (a PackDef) says who's in it;
# without one it's count of monsters, round-robin. Sometimes the pack is led by a named elite.

@export var monsters: Array[StringName] = [&"skeleton_minion"]
@export var count := 1
@export var pack: PackDef
@export var scatter := 1.5
# Chance (0-1) the pack is led by an elite, and how many affixes it gets
@export var elite_chance := 0.0
@export var elite_affixes := 2

# Seeded by whoever places the point (the dungeon generator) for repeatable packs; random otherwise
var rng := RandomNumberGenerator.new()

func members() -> Array[StringName]:
	if pack and not pack.members.is_empty():
		return pack.members.duplicate()
	var ids: Array[StringName] = []
	for i in count:
		ids.append(monsters[i % monsters.size()])
	return ids

func spawn() -> Array[Monster]:
	var spawned: Array[Monster] = []
	var parent := get_parent() as Node3D
	var ids := members()
	for i in ids.size():
		var offset := Vector3.ZERO if ids.size() == 1 else Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)) * scatter
		var monster := MonsterLibrary.spawn(ids[i], parent, global_position + offset)
		if monster:
			monster.face(-offset if offset != Vector3.ZERO else Vector3.BACK)
			spawned.append(monster)
	for monster in spawned:
		monster.brain.pack = spawned
	if not spawned.is_empty() and rng.randf() < elite_chance:
		Elites.promote(spawned[0], Elites.roll_affixes(rng, elite_affixes), Elites.roll_name(rng))
	return spawned
