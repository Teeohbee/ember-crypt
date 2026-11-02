class_name BoltShot
extends SkillEffect
# Looses a Bolt (a crossbow quarrel or a ball of witchfire) at the target, or straight ahead if it
# moved out of sight. It's dodgeable: the bolt flies where the target was, it doesn't home.

func execute(caster: Combatant, skill: SkillDef, target: Combatant, aim: Vector3) -> void:
	var start := caster.global_position + Vector3(0, 1.2, 0) + aim * 0.6
	var direction := aim
	if target:
		direction = target.global_position + Vector3(0, 1.0, 0) - start
		direction.y = 0
		direction = direction.normalized()
	var bolt := Bolt.new(caster, skill, direction)
	caster.get_parent().add_child(bolt)
	bolt.global_position = start
	if skill.params.has("sound"):
		Sound.play(skill.params["sound"], randf_range(0.92, 1.08))
