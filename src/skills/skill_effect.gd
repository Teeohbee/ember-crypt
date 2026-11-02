class_name SkillEffect
extends RefCounted
# What a skill does at its hit_time. Subclass per skill and override execute(). target is the assisted
# pick (null if nothing was in reach); aim is the flat direction the caster faces.

func execute(caster: Combatant, skill: SkillDef, target: Combatant, aim: Vector3) -> void:
	if target:
		Combat.hit(caster, target, skill)
