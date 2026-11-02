class_name Targeting
# Aim assist. On a pad you point roughly and the game picks what you meant: the best target in a cone
# around the aim, weighted by angle first, then distance. The current target gets a bonus so the pick
# doesn't flicker between two skeletons standing side by side. Pure functions over positions.

const STICKINESS := 0.25
# A barrel scores this much worse than a skeleton in the same spot: smash them on purpose, not by accident
const BREAKABLE_PENALTY := 0.6

# The best of candidates within max_range and cone_degrees (full width) of aim from origin, or null.
static func best_target(origin: Vector3, aim: Vector3, candidates: Array, max_range: float,
		cone_degrees := 90.0, current: Node3D = null) -> Combatant:
	var flat_aim := Vector3(aim.x, 0, aim.z).normalized()
	var best: Combatant = null
	var best_score := INF
	for candidate: Combatant in candidates:
		if not is_instance_valid(candidate) or not candidate.alive:
			continue
		var offset := candidate.global_position - origin
		offset.y = 0
		var distance := offset.length()
		if distance > max_range:
			continue
		var angle := 0.0 if distance < 0.01 or flat_aim == Vector3.ZERO else rad_to_deg(flat_aim.angle_to(offset))
		if angle > cone_degrees * 0.5:
			continue
		# Angle matters most: a skeleton dead ahead beats a nearer one off to the side
		var score := angle / maxf(cone_degrees * 0.5, 1.0) + distance / maxf(max_range, 0.01) * 0.5
		if candidate == current:
			score -= STICKINESS
		if candidate.is_in_group(&"breakables"):
			score += BREAKABLE_PENALTY
		if score < best_score:
			best_score = score
			best = candidate
	return best

static func in_radius(origin: Vector3, candidates: Array, radius: float) -> Array[Combatant]:
	var found: Array[Combatant] = []
	for candidate: Combatant in candidates:
		if is_instance_valid(candidate) and candidate.alive:
			var offset := candidate.global_position - origin
			offset.y = 0
			if offset.length() <= radius:
				found.append(candidate)
	return found

static func in_cone(origin: Vector3, aim: Vector3, candidates: Array, radius: float, cone_degrees: float) -> Array[Combatant]:
	var flat_aim := Vector3(aim.x, 0, aim.z).normalized()
	var found: Array[Combatant] = []
	for candidate in in_radius(origin, candidates, radius):
		var offset := candidate.global_position - origin
		offset.y = 0
		if offset.length() < 0.01 or rad_to_deg(flat_aim.angle_to(offset)) <= cone_degrees * 0.5:
			found.append(candidate)
	return found
