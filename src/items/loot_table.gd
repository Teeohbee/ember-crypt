class_name LootTable
extends Resource
# What a monster can drop. Rolling it is M4's job (Loot); this is just the data.

# Chance (0-1) to drop anything at all
@export var drop_chance := 0.3
@export var max_drops := 1
@export var gold_min := 0
@export var gold_max := 0
# Chance (0-1) of a pile of gold, rolled separately from items
@export var gold_chance := 0.5
# Rarity weights, by Item.Rarity
@export var rarity_weights := {0: 70, 1: 25, 2: 5, 3: 0}
# Restrict to these bases; empty means any that fit the item level
@export var bases: Array[ItemBase] = []
