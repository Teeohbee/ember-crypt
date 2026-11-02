extends SkillEffect
# Teleport: the Mage vanishes in a flash and reappears a short way along the aim, stopping short of
# any wall in the way. The way out when the dead get close.

func execute(caster: Combatant, skill: SkillDef, _target: Combatant, aim: Vector3) -> void:
	var from := caster.global_position
	var to := SkillMotion.clear_path(caster, from, from + aim * float(skill.params.get("distance", 8.0)))
	var world := caster.get_parent()
	SkillVfx.burst(world, from, SkillVfx.ARCANE, 14, 3.0, 0.4, 1.0)
	SkillVfx.ring(world, from, 0.9, 0.1, SkillVfx.ARCANE, 0.3)
	caster.global_position = to
	SkillVfx.ring(world, to, 0.1, 1.4, SkillVfx.ARCANE, 0.35)
	SkillVfx.flash(world, to, SkillVfx.ARCANE, 2.0, 5.0, 0.3)
	Sound.play("teleport", randf_range(0.97, 1.03))
