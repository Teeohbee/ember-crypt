class_name HeroClass
extends Resource
# A playable class: who they are on the class select screen, how they look, and what they fight with.

@export var id := ""
@export var display_name := ""
@export var epithet := ""
@export_multiline var blurb := ""
@export var model: PackedScene
# Each rig comes holding every prop it was modelled with (the Mage has a wand, a staff and two books);
# these are the ones this class keeps. The rest are removed.
@export var held: PackedStringArray = []
# Animation names from the KayKit rig
@export var idle := "Idle"
@export var chosen := "Cheer"
@export var power_name := ""
@export var power_colour := Color.WHITE
# 1-5 each, for the class select bars: toughness, damage, range, difficulty
@export var ratings := {"Toughness": 3, "Damage": 3, "Range": 3, "Difficulty": 3}
# Starting stat sheet, Stats names to values; anything missing uses Stats.DEFAULTS
@export var base_stats := {}
# Skills in button order: A, X, Y, B, RB, RT. Index 0 is the primary.
@export var skills: Array[SkillDef] = []
# Power the hero starts a fight with: the Mage starts full, the Barbarian empty and builds Fury
@export var starting_power := 0.0
