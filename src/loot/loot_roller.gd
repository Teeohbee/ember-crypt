class_name LootRoller
extends RefCounted
# Turns a LootTable into items and gold. Pure apart from the rng it's handed, so a seed rolls the same
# loot every time. Rarity comes from the table's weights, tilted by magic find; the base from those
# the item level allows, leaning toward the hero's own class (D3's smart loot); affixes from the pool
# that fits the slot and item level, more of them the rarer it is.

# Item level adds this much to flat affix values per level: an item level 11 Life roll is double a 1
const LEVEL_SCALING := 0.1
# Smart loot: bases the hero's class can use are this much likelier than other classes' bases
const OWN_CLASS_WEIGHT := 4
const AFFIX_COUNTS := {
	Item.Rarity.NORMAL: Vector2i(0, 0), Item.Rarity.MAGIC: Vector2i(1, 2),
	Item.Rarity.RARE: Vector2i(3, 4), Item.Rarity.LEGENDARY: Vector2i(5, 5),
}
const RARE_FIRST := ["Grim", "Bone", "Ash", "Dread", "Hollow", "Storm", "Gloom", "Blood", "Pale", "Ember", "Grave", "Rot"]
const RARE_SECOND := {
	ItemBase.Slot.WEAPON: ["Bite", "Reaver", "Edge", "Song", "Cleaver", "Thirst"],
	ItemBase.Slot.OFFHAND: ["Ward", "Bulwark", "Aegis", "Wall"],
	ItemBase.Slot.HEAD: ["Crown", "Visage", "Brow", "Gaze"],
	ItemBase.Slot.CHEST: ["Shell", "Mantle", "Carapace", "Hide"],
	ItemBase.Slot.HANDS: ["Grip", "Claws", "Fists", "Grasp"],
	ItemBase.Slot.FEET: ["Stride", "Trek", "March", "Path"],
	ItemBase.Slot.RING: ["Loop", "Circle", "Band", "Coil"],
	ItemBase.Slot.AMULET: ["Charm", "Talisman", "Heart", "Eye"],
}
const LEGENDARY_OWNERS := ["the Ashen King", "Saint Morrow", "the Drowned Choir", "Hollow Vane",
	"the Last Librarian", "the Bone Abbess", "Old Cinder"]

var rng: RandomNumberGenerator
var bases: Array[ItemBase]
var affixes: Array[AffixDef]

func _init(random: RandomNumberGenerator = null, base_pool: Array[ItemBase] = [], affix_pool: Array[AffixDef] = []) -> void:
	rng = random if random else RandomNumberGenerator.new()
	bases = base_pool if not base_pool.is_empty() else ItemLibrary.all_bases()
	affixes = affix_pool if not affix_pool.is_empty() else ItemLibrary.all_affixes()

# {"items": Array[Item], "gold": int}. bonus_rolls and min_rarity are for elites and bosses.
func roll_drops(table: LootTable, item_level: int, magic_find := 0.0, gold_find := 0.0, class_id := "",
		bonus_rolls := 0, min_rarity := Item.Rarity.NORMAL) -> Dictionary:
	var items: Array[Item] = []
	for i in table.max_drops + bonus_rolls:
		if i >= table.max_drops or rng.randf() < table.drop_chance:
			var base := pick_base(table, item_level, class_id)
			if base:
				items.append(roll_item(base, roll_rarity(table.rarity_weights, magic_find, min_rarity), item_level))
	var gold := 0
	if table.gold_max > 0 and rng.randf() < table.gold_chance:
		var amount := rng.randi_range(table.gold_min, table.gold_max) * (1.0 + (item_level - 1) * 0.25)
		gold = roundi(amount * (1.0 + maxf(gold_find, 0.0)))
	return {"items": items, "gold": gold}

# Magic find multiplies the weight of every rarity above normal
func roll_rarity(weights: Dictionary, magic_find := 0.0, min_rarity := Item.Rarity.NORMAL) -> int:
	var tilted := {}
	var sum := 0.0
	for rarity: int in Item.Rarity.values():
		var weight := float(weights.get(rarity, 0)) if rarity >= min_rarity else 0.0
		if rarity > Item.Rarity.NORMAL:
			weight *= 1.0 + maxf(magic_find, 0.0)
		tilted[rarity] = weight
		sum += weight
	if sum <= 0.0:
		return min_rarity
	var pick := rng.randf() * sum
	for rarity: int in tilted:
		pick -= tilted[rarity]
		if pick < 0.0 and tilted[rarity] > 0.0:
			return rarity
	return min_rarity

func pick_base(table: LootTable, item_level: int, class_id := "") -> ItemBase:
	var pool: Array = table.bases if not table.bases.is_empty() else bases
	var candidates: Array[ItemBase] = []
	var weights: Array[float] = []
	for base: ItemBase in pool:
		if base.min_level > item_level:
			continue
		candidates.append(base)
		weights.append(float(OWN_CLASS_WEIGHT if class_id != "" and base.can_be_worn_by(class_id) else 1))
	if candidates.is_empty():
		return null
	return candidates[rng.rand_weighted(PackedFloat32Array(weights))]

func roll_item(base: ItemBase, rarity: int, item_level: int) -> Item:
	var item := Item.new()
	item.base = base
	item.rarity = rarity
	item.item_level = item_level
	var range_of: Vector2i = AFFIX_COUNTS[rarity]
	var pool := _affixes_for(base, item_level)
	for i in rng.randi_range(range_of.x, range_of.y):
		if pool.is_empty():
			break
		var weights := PackedFloat32Array()
		for affix in pool:
			weights.append(float(affix.weight))
		var chosen: AffixDef = pool[rng.rand_weighted(weights)]
		pool.erase(chosen)
		# Legendaries roll in the top half of every range
		var value := roll_affix_value(chosen, item_level, 0.5 if rarity == Item.Rarity.LEGENDARY else 0.0)
		item.affixes.append({"id": chosen.id, "value": value})
	item.display_name = _name(item)
	return item

# A value between the affix's min and max (from `low_end` of the way up), on its step. Flat affixes that
# aren't fractions grow with item level.
func roll_affix_value(affix: AffixDef, item_level: int, low_end := 0.0) -> float:
	var value := lerpf(affix.min_value, affix.max_value, rng.randf_range(low_end, 1.0))
	if not affix.percent and not StatText.is_fraction(affix.stat):
		value *= 1.0 + LEVEL_SCALING * (item_level - 1)
	var step := maxf(affix.step, 0.0001)
	return snappedf(value, step)

func _affixes_for(base: ItemBase, item_level: int) -> Array[AffixDef]:
	var pool: Array[AffixDef] = []
	for affix in affixes:
		if affix.min_level <= item_level and (affix.slots.is_empty() or affix.slots.has(base.slot)):
			pool.append(affix)
	return pool

func _name(item: Item) -> String:
	var base_name := item.base.display_name
	match item.rarity:
		Item.Rarity.MAGIC:
			var affix := ItemLibrary.affix(item.affixes[0].id) if not item.affixes.is_empty() else null
			return "%s %s" % [affix.prefix, base_name] if affix and affix.prefix != "" else base_name
		Item.Rarity.RARE:
			return "%s %s" % [_pick(RARE_FIRST), _pick(RARE_SECOND[item.base.slot])]
		Item.Rarity.LEGENDARY:
			return "%s of %s" % [_pick(RARE_SECOND[item.base.slot]), _pick(LEGENDARY_OWNERS)]
	return base_name

func _pick(words: Array) -> String:
	return words[rng.randi_range(0, words.size() - 1)]
