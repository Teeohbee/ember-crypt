class_name SummonEffect
extends SkillEffect
# Raises monsters from the floor around the caster. params: monster (an id), count, max_alive (the
# most of the caster's summons up at once; the brain won't cast it again until some fall).

const RING := 1.8

func execute(caster: Combatant, skill: SkillDef, _target: Combatant, _aim: Vector3) -> void:
	var monster := caster as Monster
	if monster == null:
		return
	var id: StringName = skill.params.get("monster", &"skeleton_minion")
	var room := int(skill.params.get("max_alive", 3)) - monster.brain.living_summons()
	var count := mini(int(skill.params.get("count", 2)), room)
	for i in count:
		var angle := TAU * (float(i) / maxf(count, 1) + monster.rng.randf_range(-0.08, 0.08))
		var at := caster.global_position + Vector3(sin(angle), 0, cos(angle)) * RING
		var raised := MonsterLibrary.spawn(id, caster.get_parent(), at)
		if raised:
			raised.face(at - caster.global_position)
			raised.brain.rise()
			raised.brain.alert(monster.brain.target, true)
			monster.brain.summons.append(raised)
			caster.get_parent().add_child(Telegraph.ring(at, 1.0, 0.9, Telegraph.SUMMON))
	Sound.play("summon", randf_range(0.95, 1.05))
