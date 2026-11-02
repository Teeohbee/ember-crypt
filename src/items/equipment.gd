class_name Equipment
extends RefCounted
# What the hero wears, one item per slot. Equipping puts the item's modifiers on the stat sheet under
# the source "equip:<slot>"; taking it off removes them. Showing it on the model is M4's job.

signal changed(slot: ItemBase.Slot, item: Item)

var stats: Stats
var worn := {}

func _init(sheet: Stats) -> void:
	stats = sheet

func item_in(slot: ItemBase.Slot) -> Item:
	return worn.get(slot)

# Puts item on and returns whatever it replaced (or null)
func equip(item: Item) -> Item:
	var slot := item.base.slot
	var old := unequip(slot)
	worn[slot] = item
	var source := _source(slot)
	for modifier: Array in item.modifiers():
		stats.add_modifier(source, modifier[0], modifier[1], modifier[2])
	changed.emit(slot, item)
	return old

func unequip(slot: ItemBase.Slot) -> Item:
	var old: Item = worn.get(slot)
	if old:
		worn.erase(slot)
		stats.clear_source(_source(slot))
		changed.emit(slot, null)
	return old

func to_dict() -> Dictionary:
	var data := {}
	for slot: int in worn:
		data[str(slot)] = worn[slot].to_dict()
	return data

func load_dict(data: Dictionary) -> void:
	for slot: int in worn.keys():
		unequip(slot)
	for key: String in data:
		equip(Item.from_dict(data[key]))

func _source(slot: ItemBase.Slot) -> StringName:
	return StringName("equip:%d" % slot)
