class_name RuneDef
extends Resource
# A rune: one way to change a skill, chosen on the skills screen, one per skill. It's numbers, not code:
# apply() hands back a copy of the skill with fields multiplied or replaced and params merged. The copy's
# params carry "rune" (this rune's id), so a skill's effect can branch on it when numbers aren't enough.
# Runes live in res://src/skills/runes/<skill id>/.

@export var id: StringName
# The SkillDef id this rune belongs to
@export var skill: StringName
@export var display_name := ""
@export_multiline var description := ""
@export var unlock_level := 1
# SkillDef property names to factors: {"damage_multiplier": 1.4, "cooldown": 0.75}
@export var multiply := {}
# SkillDef property names to new values: {"damage_kind": DamageEvent.Kind.FIRE}
@export var overrides := {}
# Merged over the skill's params
@export var params := {}

func apply(original: SkillDef) -> SkillDef:
	var runed: SkillDef = original.duplicate()
	runed.params = original.params.duplicate(true)
	for field: String in multiply:
		if field in runed:
			runed.set(field, runed.get(field) * multiply[field])
		else:
			push_warning("Rune %s multiplies %s, which SkillDef doesn't have" % [id, field])
	for field: String in overrides:
		if field in runed:
			runed.set(field, overrides[field])
		else:
			push_warning("Rune %s overrides %s, which SkillDef doesn't have" % [id, field])
	runed.params.merge(params, true)
	runed.params["rune"] = id
	return runed
