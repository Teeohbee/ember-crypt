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
# What sort of thing it is, for its icon and type line: axe, sword, dagger, staff, wand, shield, tome,
# helm, chest, gloves, boots, ring, amulet
@export var kind := ""
# Takes both hands: wearing it takes the offhand off
@export var two_handed := false
# How the model sits on hand_bone. The defaults match the KayKit rigs' own right-hand props; left-hand
# shields and books sit differently (copied from the rigs' Round_Shield and Spellbook).
@export var grip_offset := Vector3(0, 0.033, 0)
@export var grip_degrees := Vector3(0, 180, 0)

func grip() -> Transform3D:
	var rotation := Basis.from_euler(Vector3(deg_to_rad(grip_degrees.x), deg_to_rad(grip_degrees.y), deg_to_rad(grip_degrees.z)))
	return Transform3D(rotation, grip_offset)

func can_be_worn_by(class_id: String) -> bool:
	return classes.is_empty() or classes.has(class_id)
