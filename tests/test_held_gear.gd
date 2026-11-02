extends GdUnitTestSuite
# What the hero holds follows what's equipped: starting gear replaces the rig's own props, a new
# weapon swaps in, a shield goes on the left hand, and taking a weapon off empties the hand.

func _hand(hero: Hero, hand: String) -> Array:
	return hero.model.find_child(hand, true, false).get_children().map(func(n: Node) -> String: return n.name)

func _item(base_id: StringName) -> Item:
	var item := Item.new()
	item.base = ItemLibrary.base(base_id)
	return item

func test_weapons_and_shields_show_on_the_hand_bones() -> void:
	var hero: Hero = auto_free(Hero.new(Session.CLASSES[0], PlayerSlot.new()))
	assert_array(_hand(hero, "handslot_r")).contains_exactly(["great_axe"])
	hero.equipment.equip(_item(&"hand_axe"))
	hero.equipment.equip(_item(&"round_shield"))
	assert_array(_hand(hero, "handslot_r")).contains_exactly(["hand_axe"])
	assert_array(_hand(hero, "handslot_l")).contains_exactly(["round_shield"])
	hero.equipment.unequip(ItemBase.Slot.WEAPON)
	assert_array(_hand(hero, "handslot_r")).is_empty()

func test_the_mage_starts_with_a_staff() -> void:
	var hero: Hero = auto_free(Hero.new(Session.CLASSES[1], PlayerSlot.new()))
	assert_array(_hand(hero, "handslot_r")).contains_exactly(["staff"])
	assert_float(hero.stats.value(Stats.DAMAGE)).is_greater(Stats.DEFAULTS[Stats.DAMAGE])
