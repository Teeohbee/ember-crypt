class_name SkillDef
extends Resource
# A skill as data: what it costs, how long it takes and how hard it hits. What it actually does lives in
# effect, a SkillEffect script, so a new skill is a .tres and (usually) a short script. Monsters' attacks
# are SkillDefs too. Hit timing comes from hit_time, not animation events: KayKit clips carry none.

@export var id: StringName
@export var display_name := ""
@export_multiline var description := ""
@export var icon: Texture2D
# A script extending SkillEffect
@export var effect: Script
# The caster's animation, by KayKit name
@export var animation := ""
# Seconds from the start of the animation to the moment the effect fires
@export var hit_time := 0.25
# Seconds from the start until the caster can act again
@export var recovery := 0.5
@export var cooldown := 0.0
# Power spent to use it (the Mage's Arcane), and gained when it hits (the Barbarian's Fury)
@export var cost := 0.0
@export var generate := 0.0
@export var damage_multiplier := 1.0
@export var damage_kind := DamageEvent.Kind.PHYSICAL
# How far away a target can be picked; melee skills step-lunge to reach it
@export var reach := 2.5
# Area of effect radius (0 for single target) and arc for cone skills
@export var radius := 0.0
@export var cone_degrees := 90.0
@export var knockback := 0.0
# Hero level that unlocks it (M5)
@export var unlock_level := 1
# Effect-specific tuning: projectile speed, leap distance, slow amount...
@export var params := {}

func instantiate_effect() -> SkillEffect:
	return effect.new() if effect else SkillEffect.new()
