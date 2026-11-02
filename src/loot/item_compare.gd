class_name ItemCompare
# What wearing an item would change: the worn items it would replace (a two-hander takes the shield
# off too) and, stat by stat, what you'd gain or lose. Green and red on the pickup popup.

# Worn items that come off if item goes on
static func replaced(equipment: Equipment, item: Item) -> Array[Item]:
	var off: Array[Item] = []
	var same := equipment.item_in(item.base.slot)
	if same:
		off.append(same)
	if item.base.two_handed:
		var offhand := equipment.item_in(ItemBase.Slot.OFFHAND)
		if offhand:
			off.append(offhand)
	elif item.base.slot == ItemBase.Slot.OFFHAND:
		var weapon := equipment.item_in(ItemBase.Slot.WEAPON)
		if weapon and weapon.base.two_handed:
			off.append(weapon)
	return off

# [{"text": "+3 Damage", "better": true}, ...] in StatText order, unchanged stats left out
static func deltas(item: Item, old: Array[Item]) -> Array[Dictionary]:
	var totals := _totals([item])
	var before := _totals(old)
	for key: Array in before:
		totals[key] = totals.get(key, 0.0) - before[key]
	var found: Array[Dictionary] = []
	for stat: StringName in StatText.NAMES:
		for percent in [false, true]:
			var amount: float = totals.get([stat, percent], 0.0)
			if absf(amount) < 0.0001:
				continue
			var text := StatText.line(stat, 0.0 if percent else amount, amount if percent else 0.0)
			found.append({"text": text, "better": amount > 0.0})
	return found

# [stat, is_percent] -> summed amount
static func _totals(items: Array[Item]) -> Dictionary:
	var totals := {}
	for item in items:
		for modifier: Array in item.modifiers():
			if modifier[1] != 0.0:
				totals[[modifier[0], false]] = totals.get([modifier[0], false], 0.0) + modifier[1]
			if modifier[2] != 0.0:
				totals[[modifier[0], true]] = totals.get([modifier[0], true], 0.0) + modifier[2]
	return totals
