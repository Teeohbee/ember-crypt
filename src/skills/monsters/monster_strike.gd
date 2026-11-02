class_name MonsterStrike
extends SkillEffect
# A monster's melee swing. It hits whoever is in front of it when the blow lands, not whoever it was
# swinging at, so stepping out of reach during the wind-up (or the telegraph) makes it miss. radius, if
# set, makes it a wider arc of cone_degrees; otherwise reach decides.

# A little forgiveness, so a hero brushing the edge of reach still gets hit
const SLACK := 0.6

func execute(caster: Combatant, skill: SkillDef, _target: Combatant, aim: Vector3) -> void:
	var reach := (skill.radius if skill.radius > 0.0 else skill.reach) + SLACK
	for victim in Targeting.in_cone(caster.global_position, aim, caster.hostiles(), reach, skill.cone_degrees):
		Combat.hit(caster, victim, skill)
	if skill.params.get("shake", 0.0) > 0.0:
		Feedback.shake(skill.params["shake"])
