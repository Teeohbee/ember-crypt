class_name AffixDef
extends Resource
# One magic property an item can roll: "+12% Attack Speed". Rolls a value between min and max, scaled
# up with item level.

@export var id: StringName
# Shown with the rolled value: "+%d Armour", "+%d%% Critical Hit Damage"
@export var text := ""
@export var stat: StringName
# Whether the rolled value is a flat amount or a percent (fraction) modifier
@export var percent := false
@export var min_value := 1.0
@export var max_value := 5.0
# Slots it can roll on; empty means any
@export var slots: Array[ItemBase.Slot] = []
@export var min_level := 1
@export var weight := 10
# The word a magic item takes from it: "Keen Hand Axe"
@export var prefix := ""
# Rolled values round to this: 1 for whole numbers, 0.01 for whole percents
@export var step := 1.0
