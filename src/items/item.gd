class_name Item
extends RefCounted
# A rolled item: a base, a rarity, an item level and its affixes. Plain data, so it saves as a
# dictionary (to_dict / from_dict) and goes on the floor, in bags, in the stash, on the hero.

enum Rarity { NORMAL, MAGIC, RARE, LEGENDARY }

const RARITY_COLOURS := {
	Rarity.NORMAL: Color(0.86, 0.84, 0.8),
	Rarity.MAGIC: Color(0.42, 0.55, 1.0),
	Rarity.RARE: Color(1.0, 0.86, 0.3),
	Rarity.LEGENDARY: Color(1.0, 0.5, 0.12),
}

var base: ItemBase
var rarity := Rarity.NORMAL
var item_level := 1
var display_name := ""
# Each {"id": affix id, "value": rolled value}
var affixes: Array[Dictionary] = []

func colour() -> Color:
	return RARITY_COLOURS[rarity]

# [stat, flat, percent] triples: the base's stats plus each affix. Equipment hands them to Stats.
func modifiers() -> Array:
	var all := []
	for stat: StringName in base.base_stats:
		all.append([StringName(stat), float(base.base_stats[stat]), 0.0])
	for rolled in affixes:
		var affix := ItemLibrary.affix(rolled.id)
		if affix:
			all.append([affix.stat, 0.0 if affix.percent else rolled.value, rolled.value if affix.percent else 0.0])
	return all

func to_dict() -> Dictionary:
	return {"base": String(base.id), "rarity": rarity, "item_level": item_level, "name": display_name, "affixes": affixes.duplicate(true)}

static func from_dict(data: Dictionary) -> Item:
	var item := Item.new()
	item.base = ItemLibrary.base(StringName(data.base))
	item.rarity = int(data.get("rarity", Rarity.NORMAL))
	item.item_level = int(data.get("item_level", 1))
	item.display_name = data.get("name", item.base.display_name if item.base else "")
	for rolled: Dictionary in data.get("affixes", []):
		item.affixes.append({"id": StringName(rolled.id), "value": float(rolled.value)})
	return item
