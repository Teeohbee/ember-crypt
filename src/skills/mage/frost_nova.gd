extends SkillEffect
# Frost Nova: a ring of ice bursts out from the Mage, hurting and chilling everything close. Chilled
# enemies move and attack slower for a few seconds (a status on their stat sheet, so any brain that
# reads move_speed and attack_speed slows down with it) and wear a frost aura while it lasts.

func execute(caster: Combatant, skill: SkillDef, _target: Combatant, _aim: Vector3) -> void:
	var seconds := float(skill.params.get("seconds", 3.0))
	var chill := [
		[Stats.MOVE_SPEED, 0.0, -float(skill.params.get("slow", 0.6))],
		[Stats.ATTACK_SPEED, 0.0, -float(skill.params.get("attack_slow", 0.4))],
	]
	for victim in Targeting.in_radius(caster.global_position, caster.hostiles(), skill.radius):
		Combat.hit(caster, victim, skill)
		if victim.alive:
			Statuses.of(victim).apply(&"chill", seconds, chill, SkillVfx.aura(SkillVfx.FROST, 0.8))
	var world := caster.get_parent()
	Sound.play("frost_nova", randf_range(0.97, 1.03))
	SkillVfx.ring(world, caster.global_position, 0.4, skill.radius, SkillVfx.FROST, 0.45, 0.25)
	SkillVfx.burst(world, caster.global_position, SkillVfx.FROST, 24, skill.radius * 2.0, 0.5, 0.1)
	SkillVfx.flash(world, caster.global_position, SkillVfx.FROST, 2.5, skill.radius + 3.0, 0.4)
	Feedback.shake(0.2)
