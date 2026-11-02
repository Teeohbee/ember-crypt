class_name Pricing
extends RefCounted
# What an item's worth in gold: more for rarity, item level and every affix. Merchants sell at the
# full value and buy at a quarter of it, as merchants do.

const BASE := 20.0
const PER_LEVEL := 6.0
const PER_AFFIX := 0.2
const RARITY := {Item.Rarity.NORMAL: 1.0, Item.Rarity.MAGIC: 2.5, Item.Rarity.RARE: 6.0, Item.Rarity.LEGENDARY: 15.0}
const SELL_SHARE := 4

static func value(item: Item) -> int:
	var level := BASE + PER_LEVEL * maxi(item.item_level - 1, 0)
	return roundi(level * RARITY[item.rarity] * (1.0 + PER_AFFIX * item.affixes.size()))

static func buy_price(item: Item) -> int:
	return value(item)

static func sell_price(item: Item) -> int:
	return maxi(value(item) / SELL_SHARE, 1)
