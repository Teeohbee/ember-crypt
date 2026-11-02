extends SkillEffect
# Bash: one heavy blow with the axe that knocks its target back. The swing has already stepped into
# reach (strike_range); if the target got away during the wind-up, or there wasn't one, it lands on
# whatever is closest in a short arc ahead instead, and failing that it whistles through the air.

func execute(caster: Combatant, skill: SkillDef, target: Combatant, aim: Vector3) -> void:
	Sound.play("swing", randf_range(0.92, 1.05))
	var strike_range: float = skill.params.get("strike_range", 1.6)
	if target == null or _flat_distance(caster, target) > strike_range + 1.0:
		target = _nearest(caster, Targeting.in_cone(caster.global_position, aim, caster.hostiles(), strike_range + 0.8, skill.cone_degrees))
	if target:
		Combat.hit(caster, target, skill)

static func _flat_distance(a: Node3D, b: Node3D) -> float:
	var offset := b.global_position - a.global_position
	offset.y = 0.0
	return offset.length()

static func _nearest(caster: Combatant, candidates: Array[Combatant]) -> Combatant:
	var best: Combatant = null
	for candidate in candidates:
		if best == null or _flat_distance(caster, candidate) < _flat_distance(caster, best):
			best = candidate
	return best
