class_name ItemSwap
# Moving gear between the bag and the hero. Whatever comes off goes into the bag, so a swap only
# happens if the bag has room for it all; nothing is ever dropped or lost on the way.

# Puts item on (from the bag, or from the floor if it isn't in the bag). False, and nothing moved, if
# the class can't wear it or the bag can't take what comes off.
static func equip(item: Item, equipment: Equipment, bag: Inventory, class_id: String) -> bool:
	if not item.base.can_be_worn_by(class_id):
		return false
	var off := ItemCompare.replaced(equipment, item)
	var in_bag := bag.items.has(item)
	if bag.items.size() - (1 if in_bag else 0) + off.size() > bag.capacity:
		return false
	if in_bag:
		bag.remove(item)
	for worn in off:
		equipment.unequip(worn.base.slot)
	equipment.equip(item)
	for worn in off:
		bag.add(worn)
	return true

static func unequip(slot: ItemBase.Slot, equipment: Equipment, bag: Inventory) -> bool:
	if equipment.item_in(slot) == null or bag.is_full():
		return false
	bag.add(equipment.unequip(slot))
	return true
