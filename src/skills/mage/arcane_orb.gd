extends SkillEffect
# Arcane Orb: launches a slow ball of arcane power that bursts on the first enemy (or wall) it meets,
# or at the end of its range, hurting everything in the blast. The flight is an ArcaneOrb node.

func execute(caster: Combatant, skill: SkillDef, target: Combatant, aim: Vector3) -> void:
	var direction := aim
	if target:
		direction = target.global_position - caster.global_position
		direction.y = 0
		direction = direction.normalized() if direction.length_squared() > 0.0001 else aim
	var orb := ArcaneOrb.new(caster, skill, direction)
	caster.get_parent().add_child(orb)
	orb.global_position = caster.global_position + direction * 0.8 + Vector3(0, ArcaneOrb.HEIGHT, 0)
	Sound.play("arcane_orb", randf_range(0.95, 1.05))
