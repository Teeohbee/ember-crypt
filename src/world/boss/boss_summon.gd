class_name BossSummon
extends SkillEffect
# The boss calls its guard out of the floor in a ring around it. They're ordinary skeletons with
# ordinary brains, woken and pointed at whoever the boss is fighting. params: monster, count.

const RING := 3.2

func execute(caster: Combatant, skill: SkillDef, target: Combatant, _aim: Vector3) -> void:
	var boss := caster as Monster
	if boss == null or not boss.has_node("BossBrain"):
		return
	var brain: BossBrain = boss.get_node("BossBrain")
	var id: StringName = skill.params.get("monster", &"skeleton_minion")
	var count := mini(int(skill.params.get("count", 3)), BossBrain.MAX_SUMMONS - brain.living_summons())
	for i in count:
		var angle := TAU * (float(i) / maxf(count, 1)) + boss.rotation.y
		var at := boss.global_position + Vector3(sin(angle), 0, cos(angle)) * RING
		var raised := MonsterLibrary.spawn(id, boss.get_parent(), at)
		if raised:
			raised.face(at - boss.global_position)
			raised.brain.rise()
			if is_instance_valid(target):
				raised.brain.alert(target)
			brain.summons.append(raised)
			boss.get_parent().add_child(Telegraph.ring(at, 1.0, 0.9, Telegraph.SUMMON))
	Sound.play("summon", 0.85)
