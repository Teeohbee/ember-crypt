class_name EliteAffixDef
extends Resource
# One elite affix (Fast, Molten, Shielding...) as data: stat modifiers, and optionally a behaviour,
# a Node script taking the Monster in _init, added to the elite as a child.

@export var id: StringName
@export var display_name := ""
# Tints the elite's glow and its line on the name plate
@export var colour := Color.WHITE
# Stats names to fractions (0.5 is +50%) and to flat amounts
@export var percent := {}
@export var flat := {}
@export var behaviour: Script
