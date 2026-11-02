class_name SkillMotion
extends RefCounted
# Skills that move the caster (Leap, Teleport) mustn't carry them through a wall. clear_path() casts
# from where they are to where they want to be, at chest height, ignoring every combatant, and stops
# them a little short of the first wall in the way.

const CHEST := 0.9
const MARGIN := 0.6

static func clear_path(caster: Node3D, from: Vector3, to: Vector3) -> Vector3:
	var flat := to - from
	flat.y = 0
	if flat.length_squared() < 0.0001:
		return from
	var exclude: Array[RID] = []
	for node in caster.get_tree().get_nodes_in_group(&"combatants"):
		if node is CollisionObject3D:
			exclude.append(node.get_rid())
	var query := PhysicsRayQueryParameters3D.create(from + Vector3(0, CHEST, 0), from + flat + Vector3(0, CHEST, 0))
	query.exclude = exclude
	var hit := caster.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return from + flat
	var reach := maxf((hit.position - query.from).length() - MARGIN, 0.0)
	return from + flat.normalized() * reach
