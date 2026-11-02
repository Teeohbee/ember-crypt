class_name MonsterDef
extends Resource
# A kind of monster as data. Adding a monster should mean adding one of these, not code.

@export var id: StringName
@export var display_name := ""
@export var model: PackedScene
# Props to keep in hand (same scheme as HeroClass.held); everything else the rig holds is removed
@export var held: PackedStringArray = []
@export var scale := 1.0
# Stats names to values; anything missing uses Stats.DEFAULTS
@export var base_stats := {}
# Attacks, as SkillDefs, best first
@export var skills: Array[SkillDef] = []
# melee, tank, ranged, caster: which behaviour a brain gives it (M3)
@export var archetype: StringName = &"melee"
@export var aggro_range := 12.0
# How far from where it started it will follow a hero before giving up and walking home
@export var leash := 24.0
# Ranged kiters back away from a hero closer than this (0 never backs off)
@export var keep_away := 0.0
# Shielded monsters take this much less (0-1) from hits landing within block_arc of their front
@export var block := 0.0
@export var block_arc := 120.0
# Seconds between flinches when hit; a big number for things that don't flinch
@export var flinch_cooldown := 1.0
# KayKit skeletons come empty-handed; these go on the handslot bones
@export var weapon_right: PackedScene
@export var weapon_left: PackedScene
@export var xp := 10
# Monster level, for loot item level and XP scaling
@export var level := 1
@export var is_boss := false
# What it drops (M4); null uses Loot's default table
@export var loot_table: LootTable
@export var idle_animation := "Idle"
@export var walk_animation := "Walking_D_Skeletons"
@export var run_animation := "Running_A"
@export var hit_animation := "Hit_A"
@export var death_animation := "Death_A"
