class_name ItemBase
extends Resource
# A kind of item before it's rolled: a hand axe, a round shield. Rolled Items point back at one.

enum Slot { WEAPON, OFFHAND, HEAD, CHEST, HANDS, FEET, RING, AMULET }

@export var id: StringName
@export var display_name := ""
@export var slot := Slot.WEAPON
# What the hero holds (KayKit weapon gltf), shown on hand_bone; null for gear with no model
@export var model: PackedScene
@export var hand_bone := "handslot_r"
# Class ids that can equip it; empty means anyone
@export var classes: PackedStringArray = []
# Stats every roll of this base has, Stats names to flat values (weapon damage, shield armour)
@export var base_stats := {}
# The lowest item level it can drop at
@export var min_level := 1
@export var icon: Texture2D
