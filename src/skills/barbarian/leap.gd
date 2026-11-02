extends SkillEffect
# Leap: the Barbarian hurls himself at a target (or a fixed distance ahead if there isn't one) and
# crashes down, hitting everything around the landing. The flight itself is a LeapFlight node, so
# the damage lands when he does, not when he takes off.

func execute(caster: Combatant, skill: SkillDef, target: Combatant, aim: Vector3) -> void:
	var from := caster.global_position
	var to: Vector3 = from + aim * float(skill.params.get("distance", 7.0))
	if target:
		var offset := target.global_position - from
		offset.y = 0
		# Land at the target's feet, not on top of it
		to = from + offset.normalized() * maxf(offset.length() - 1.0, 0.0)
	to = SkillMotion.clear_path(caster, from, to)
	var flight := LeapFlight.new(caster, skill, from, to)
	caster.add_child(flight)
	Sound.play("leap")
