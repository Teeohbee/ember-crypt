extends GdUnitTestSuite
# The rules around gear, on plain objects: how stats read, what an item gains or loses over what's
# worn, and equipping from the bag (two-handers, class limits, a full bag).

func _item(base_id: StringName, affixes: Array[Dictionary] = [], rarity := Item.Rarity.NORMAL) -> Item:
	var item := Item.new()
	item.base = ItemLibrary.base(base_id)
	item.display_name = item.base.display_name
	item.rarity = rarity
	item.affixes = affixes
	return item

func test_stats_read_as_words() -> void:
	assert_str(StatText.line(Stats.ARMOUR, 12.0, 0.0)).is_equal("+12 Armour")
	assert_str(StatText.line(Stats.DAMAGE, 6.0, 0.0, false)).is_equal("6 Damage")
	assert_str(StatText.line(Stats.CRIT_CHANCE, 0.03, 0.0)).is_equal("+3% Critical Hit Chance")
	assert_str(StatText.line(Stats.ATTACK_SPEED, 0.0, 0.07)).is_equal("+7% Attack Speed")
	assert_str(StatText.line(Stats.HEALTH_REGEN, 1.2, 0.0)).is_equal("+1.2 Life per Second")
	assert_str(StatText.line(Stats.ARMOUR, -4.0, 0.0)).is_equal("-4 Armour")

func test_compare_shows_gains_and_losses() -> void:
	var worn := _item(&"hand_axe", [{"id": &"life", "value": 10.0}])
	var found := _item(&"great_axe")
	var deltas := ItemCompare.deltas(found, [worn])
	assert_array(deltas.map(func(d: Dictionary) -> String: return d.text)) \
		.contains_exactly(["+3 Damage", "-10 Life"])
	assert_bool(deltas[0].better).is_true()
	assert_bool(deltas[1].better).is_false()

func test_compare_against_nothing_is_all_gain() -> void:
	var deltas := ItemCompare.deltas(_item(&"round_shield"), [])
	assert_str(deltas[0].text).is_equal("+12 Armour")

func test_a_two_hander_is_compared_against_weapon_and_offhand() -> void:
	var equipment := Equipment.new(Stats.new())
	equipment.equip(_item(&"hand_axe"))
	equipment.equip(_item(&"round_shield"))
	var replaced := ItemCompare.replaced(equipment, _item(&"great_axe"))
	assert_int(replaced.size()).is_equal(2)

func test_a_shield_replaces_a_two_hander() -> void:
	var equipment := Equipment.new(Stats.new())
	equipment.equip(_item(&"great_axe"))
	var replaced := ItemCompare.replaced(equipment, _item(&"round_shield"))
	assert_str(String(replaced[0].base.id)).is_equal("great_axe")

func test_equipping_from_the_bag_swaps_the_old_item_into_it() -> void:
	var stats := Stats.new()
	var equipment := Equipment.new(stats)
	var bag := Inventory.new(5)
	var old := _item(&"hand_axe")
	var new := _item(&"great_axe")
	equipment.equip(old)
	bag.add(new)
	assert_bool(ItemSwap.equip(new, equipment, bag, "barbarian")).is_true()
	assert_object(equipment.item_in(ItemBase.Slot.WEAPON)).is_same(new)
	assert_array(bag.items).contains_exactly([old])
	assert_float(stats.value(Stats.DAMAGE)).is_equal(16.0)

func test_a_two_hander_sends_the_shield_to_the_bag_too() -> void:
	var equipment := Equipment.new(Stats.new())
	var bag := Inventory.new(5)
	equipment.equip(_item(&"hand_axe"))
	equipment.equip(_item(&"round_shield"))
	var axe := _item(&"great_axe")
	bag.add(axe)
	assert_bool(ItemSwap.equip(axe, equipment, bag, "barbarian")).is_true()
	assert_object(equipment.item_in(ItemBase.Slot.OFFHAND)).is_null()
	assert_int(bag.items.size()).is_equal(2)

func test_no_room_for_what_comes_off_means_no_swap() -> void:
	var equipment := Equipment.new(Stats.new())
	var bag := Inventory.new(1)
	equipment.equip(_item(&"hand_axe"))
	equipment.equip(_item(&"round_shield"))
	var axe := _item(&"great_axe")
	bag.add(axe)
	assert_bool(ItemSwap.equip(axe, equipment, bag, "barbarian")).is_false()
	assert_str(String(equipment.item_in(ItemBase.Slot.WEAPON).base.id)).is_equal("hand_axe")
	assert_array(bag.items).contains_exactly([axe])

func test_another_classs_item_cant_be_worn() -> void:
	var equipment := Equipment.new(Stats.new())
	var bag := Inventory.new()
	var staff := _item(&"staff")
	bag.add(staff)
	assert_bool(ItemSwap.equip(staff, equipment, bag, "barbarian")).is_false()
	assert_array(bag.items).contains_exactly([staff])

func test_unequipping_needs_room_in_the_bag() -> void:
	var equipment := Equipment.new(Stats.new())
	var bag := Inventory.new(1)
	equipment.equip(_item(&"leather_cap"))
	bag.add(_item(&"ring"))
	assert_bool(ItemSwap.unequip(ItemBase.Slot.HEAD, equipment, bag)).is_false()
	bag.items.clear()
	assert_bool(ItemSwap.unequip(ItemBase.Slot.HEAD, equipment, bag)).is_true()
	assert_object(equipment.item_in(ItemBase.Slot.HEAD)).is_null()
	assert_int(bag.items.size()).is_equal(1)

func test_starting_gear_suits_each_class() -> void:
	for hero_class in Session.CLASSES:
		var equipment := Equipment.new(Stats.new())
		StartingGear.give(hero_class.id, equipment)
		var weapon := equipment.item_in(ItemBase.Slot.WEAPON)
		assert_object(weapon).is_not_null()
		assert_bool(weapon.base.can_be_worn_by(hero_class.id)).is_true()

func test_every_base_with_a_model_names_a_hand_the_rigs_have() -> void:
	for base in ItemLibrary.all_bases():
		if base.model:
			assert_array(HeroModel.HAND_SLOTS).contains([base.hand_bone])
