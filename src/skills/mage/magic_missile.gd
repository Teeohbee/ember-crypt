extends SkillEffect
# Magic Missile: a bolt of arcane force from the staff that curls toward the target aim assist picked,
# or flies straight on if nothing was in reach. The bolt is an ArcaneMissile from a pool.

func execute(caster: Combatant, skill: SkillDef, target: Combatant, aim: Vector3) -> void:
	Sound.play("missile", randf_range(0.95, 1.08))
	ArcaneMissile.fire(caster, skill, target, aim)
