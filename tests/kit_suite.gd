@abstract
class_name KitSuite
extends GdUnitTestSuite
# Base for the combat kit's skill suites: a caster and some skeletons-in-spirit (bare Combatants)
# placed on a flat floor, with skills fired straight through their effects so nothing waits on timers.

func caster(team := Combatant.Team.HEROES) -> Combatant:
	var body: Combatant = auto_free(Combatant.new())
	body.team = team
	body.stats.set_base(Stats.CRIT_CHANCE, 0.0)
	add_child(body)
	return body

func monster(at: Vector3) -> Combatant:
	var body: Combatant = auto_free(Combatant.new())
	body.position = at
	add_child(body)
	return body

func skill(path: String) -> SkillDef:
	return load(path) as SkillDef

func fire(skill_def: SkillDef, by: Combatant, aim := Vector3.FORWARD, target: Combatant = null) -> void:
	skill_def.instantiate_effect().execute(by, skill_def, target, aim)

func hurt(body: Combatant) -> bool:
	return body.health < body.max_health()

# Steps a node's physics by hand, 1/60 s at a time, for up to seconds of game time
func step(node: Node, seconds: float) -> void:
	for i in int(seconds * 60.0):
		if not is_instance_valid(node) or not node.is_inside_tree():
			return
		node._physics_process(1.0 / 60.0)
