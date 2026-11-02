extends SkillEffect
# Cleave: a wide swing of the axe that hits everything in an arc in front, whether or not aim assist
# found a target. Costs Fury; the more it catches, the harder the camera kicks.

func execute(caster: Combatant, skill: SkillDef, _target: Combatant, aim: Vector3) -> void:
	var caught := Targeting.in_cone(caster.global_position, aim, caster.hostiles(), skill.radius, skill.cone_degrees)
	for victim in caught:
		Combat.hit(caster, victim, skill)
	Sound.play("cleave", randf_range(0.92, 1.08))
	var world := caster.get_parent()
	var front := caster.global_position + aim * skill.radius * 0.55
	SkillVfx.ring(world, front, 0.4, skill.radius * 0.7, SkillVfx.DUST, 0.3, 0.2)
	SkillVfx.burst(world, front, SkillVfx.DUST, 10, 4.0, 0.4)
	if not caught.is_empty():
		Feedback.shake(minf(0.15 + 0.05 * caught.size(), 0.4))
