class_name DamageEvent
extends RefCounted
# One hit, from swing to number: who hit whom with what, and what Combat.resolve() made of it.

enum Kind { PHYSICAL, FIRE, COLD, LIGHTNING, ARCANE, POISON }

var source: Combatant
var target: Combatant
var skill: SkillDef
var kind := Kind.PHYSICAL
# Before resolve, the raw damage; after, what the target loses
var amount := 0.0
var crit := false
# Metres the target is shoved away from the source
var knockback := 0.0
var killed := false
