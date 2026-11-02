class_name Vendor
extends RefCounted
# A merchant's shelf and the rules of trading with it. Stock is plain gear the hero could find at
# their level; anything sold to him goes on the shelf to be bought back (at the full price, naturally).

enum Result { OK, TOO_POOR, BAG_FULL, NOT_HERE }

var stock: Array[Item] = []

func buy(item: Item, bag: Inventory) -> Result:
	if not item in stock:
		return Result.NOT_HERE
	if bag.is_full():
		return Result.BAG_FULL
	if not bag.spend_gold(Pricing.buy_price(item)):
		return Result.TOO_POOR
	stock.erase(item)
	bag.add(item)
	return Result.OK

func sell(item: Item, bag: Inventory) -> Result:
	if not bag.remove(item):
		return Result.NOT_HERE
	bag.add_gold(Pricing.sell_price(item))
	stock.append(item)
	return Result.OK

# count normal items from the bases a hero of level could find
static func roll_stock(bases: Array, level: int, rng: RandomNumberGenerator, count: int) -> Array[Item]:
	var fitting := bases.filter(func(base: ItemBase) -> bool: return base.min_level <= level)
	var rolled: Array[Item] = []
	if fitting.is_empty():
		return rolled
	for i in count:
		var item := Item.new()
		item.base = fitting[rng.randi_range(0, fitting.size() - 1)]
		item.item_level = level
		item.display_name = item.base.display_name
		rolled.append(item)
	return rolled

# Every item base in the game
static func all_bases() -> Array[ItemBase]:
	var found: Array[ItemBase] = []
	if not DirAccess.dir_exists_absolute(ItemLibrary.BASES_DIR):
		return found
	for file in ResourceLoader.list_directory(ItemLibrary.BASES_DIR):
		if file.ends_with(".tres"):
			var base := load(ItemLibrary.BASES_DIR + file) as ItemBase
			if base:
				found.append(base)
	return found
