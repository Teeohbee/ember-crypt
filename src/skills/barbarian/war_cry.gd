extends SkillEffect
# War Cry: a bellow that hardens the Barbarian and any ally close by (armour, a little damage) for a
# few seconds, and stokes Fury on the spot, so it's how a fight starts when the bar is empty.

func execute(caster: Combatant, skill: SkillDef, _target: Combatant, _aim: Vector3) -> void:
	var seconds := float(skill.params.get("seconds", 8.0))
	var modifiers := [
		[Stats.ARMOUR, float(skill.params.get("armour", 30.0)), float(skill.params.get("armour_percent", 0.25))],
		[Stats.DAMAGE, 0.0, float(skill.params.get("damage_percent", 0.1))],
	]
	var allies: Array = caster.get_tree().get_nodes_in_group(Combatant.TEAM_GROUPS[caster.team])
	for ally in Targeting.in_radius(caster.global_position, allies, skill.radius):
		Statuses.of(ally).apply(&"war_cry", seconds, modifiers, SkillVfx.aura(SkillVfx.FURY, 1.0))
	caster.gain_power(float(skill.params.get("fury", 30.0)))
	var world := caster.get_parent()
	Sound.play("war_cry")
	SkillVfx.ring(world, caster.global_position, 0.5, skill.radius, SkillVfx.FURY, 0.6)
	SkillVfx.flash(world, caster.global_position, SkillVfx.FURY, 2.5, 8.0, 0.5)
	Feedback.shake(0.25)
