class_name SpawnPoint
extends Marker3D
# Where a pack of monsters starts. Zones place these; spawn() brings the pack in, scattered around the
# point. M3 grows this into proper packs and elites.

@export var monsters: Array[StringName] = [&"skeleton_minion"]
@export var count := 1
@export var scatter := 1.5
# Chance (0-1) the pack is led by an elite (M3)
@export var elite_chance := 0.0

func spawn() -> Array[Monster]:
	var spawned: Array[Monster] = []
	var parent := get_parent() as Node3D
	for i in count:
		var id: StringName = monsters[i % monsters.size()]
		var offset := Vector3.ZERO if count == 1 else Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * scatter
		var monster := MonsterLibrary.spawn(id, parent, global_position + offset)
		if monster:
			monster.face(-offset if offset != Vector3.ZERO else Vector3.BACK)
			spawned.append(monster)
	return spawned
