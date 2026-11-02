class_name BossSlam
extends SkillEffect
# The boss brings its axe down a few metres ahead: everyone in the circle there is hit and thrown
# back, the floor flashes and the camera jumps. params: ahead (metres in front of the boss).

static func landing(caster: Combatant, aim: Vector3, skill: SkillDef) -> Vector3:
	var flat := Vector3(aim.x, 0, aim.z).normalized()
	return caster.global_position + flat * float(skill.params.get("ahead", 3.0))

func execute(caster: Combatant, skill: SkillDef, _target: Combatant, aim: Vector3) -> void:
	var point := landing(caster, aim, skill)
	for victim in Targeting.in_radius(point, caster.hostiles(), skill.radius + 0.3):
		Combat.hit(caster, victim, skill)
	if caster.is_inside_tree():
		caster.get_parent().add_child(Telegraph.ring(point, skill.radius, 0.2, Telegraph.FIRE))
	Feedback.shake(0.8)
	Sound.play("boss_slam")
