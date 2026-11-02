extends GdUnitTestSuite
# Loot rolls: seeded, so exact. Rarity weights and magic find, item level gating bases and affixes,
# affix counts by rarity, values on their step, names, gold.

func _roller(seed_value := 7) -> LootRoller:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return LootRoller.new(rng)

func _table(chance := 1.0) -> LootTable:
	var table := LootTable.new()
	table.drop_chance = chance
	table.max_drops = 1
	table.gold_chance = 0.0
	return table

func test_the_same_seed_rolls_the_same_loot() -> void:
	var first := _roller(42).roll_drops(_table(), 3)
	var second := _roller(42).roll_drops(_table(), 3)
	assert_int(first.items.size()).is_equal(1)
	assert_dict(first.items[0].to_dict()).is_equal(second.items[0].to_dict())

func test_rarity_follows_the_weights() -> void:
	var roller := _roller()
	assert_int(roller.roll_rarity({0: 0, 1: 1, 2: 0, 3: 0})).is_equal(Item.Rarity.MAGIC)
	assert_int(roller.roll_rarity({0: 0, 1: 0, 2: 0, 3: 5})).is_equal(Item.Rarity.LEGENDARY)

func test_magic_find_makes_better_rarities_more_likely() -> void:
	var weights := {0: 70, 1: 25, 2: 5, 3: 0}
	var plain := _count_above_normal(_roller(1), weights, 0.0)
	var lucky := _count_above_normal(_roller(1), weights, 2.0)
	assert_int(lucky).is_greater(plain + 100)

func _count_above_normal(roller: LootRoller, weights: Dictionary, magic_find: float) -> int:
	var count := 0
	for i in 1000:
		if roller.roll_rarity(weights, magic_find) > Item.Rarity.NORMAL:
			count += 1
	return count

func test_a_minimum_rarity_lifts_the_roll() -> void:
	var roller := _roller()
	for i in 50:
		assert_int(roller.roll_rarity({0: 100, 1: 0, 2: 0, 3: 0}, 0.0, Item.Rarity.RARE)).is_greater_equal(Item.Rarity.RARE)

func test_bases_above_the_item_level_never_drop() -> void:
	var roller := _roller()
	for i in 200:
		assert_int(roller.pick_base(_table(), 1).min_level).is_equal(1)

func test_a_table_can_restrict_the_bases() -> void:
	var table := _table()
	table.bases = [ItemLibrary.base(&"ring")]
	assert_str(String(_roller().pick_base(table, 10).id)).is_equal("ring")

func test_bases_lean_toward_the_heros_class() -> void:
	var roller := _roller(3)
	var mage_only := 0
	var barbarian_only := 0
	for i in 600:
		var base := roller.pick_base(_table(), 10, "mage")
		if base.classes.has("mage"):
			mage_only += 1
		elif base.classes.has("barbarian"):
			barbarian_only += 1
	assert_int(mage_only).is_greater(barbarian_only * 2)

func test_affix_count_grows_with_rarity() -> void:
	var roller := _roller()
	var ring := ItemLibrary.base(&"ring")
	for i in 30:
		assert_int(roller.roll_item(ring, Item.Rarity.NORMAL, 10).affixes.size()).is_equal(0)
		assert_int(roller.roll_item(ring, Item.Rarity.MAGIC, 10).affixes.size()).is_between(1, 2)
		assert_int(roller.roll_item(ring, Item.Rarity.RARE, 10).affixes.size()).is_between(3, 4)
		assert_int(roller.roll_item(ring, Item.Rarity.LEGENDARY, 10).affixes.size()).is_equal(5)

func test_affixes_fit_the_slot_and_item_level_and_never_repeat() -> void:
	var roller := _roller()
	var boots := ItemLibrary.base(&"boots")
	for i in 100:
		var item := roller.roll_item(boots, Item.Rarity.RARE, 1)
		var seen := {}
		for rolled in item.affixes:
			var affix := ItemLibrary.affix(rolled.id)
			assert_bool(affix.slots.is_empty() or affix.slots.has(ItemBase.Slot.FEET)).is_true()
			assert_int(affix.min_level).is_equal(1)
			assert_bool(seen.has(rolled.id)).is_false()
			seen[rolled.id] = true

func test_affix_values_land_on_their_step_within_range() -> void:
	var roller := _roller()
	var crit := ItemLibrary.affix(&"crit_chance")
	for i in 100:
		var value := roller.roll_affix_value(crit, 1)
		assert_float(value).is_between(crit.min_value, crit.max_value)
		assert_float(fmod(value / crit.step + 0.0001, 1.0)).is_less(0.001)

func test_flat_affixes_grow_with_item_level_but_fractions_dont() -> void:
	var life := ItemLibrary.affix(&"life")
	var crit := ItemLibrary.affix(&"crit_chance")
	var low := _roller(5).roll_affix_value(life, 1)
	var high := _roller(5).roll_affix_value(life, 11)
	assert_float(high).is_greater_equal(low * 1.8)
	assert_float(_roller(5).roll_affix_value(crit, 11)).is_less_equal(crit.max_value)

func test_names_follow_rarity() -> void:
	var roller := _roller()
	var axe := ItemLibrary.base(&"hand_axe")
	assert_str(roller.roll_item(axe, Item.Rarity.NORMAL, 1).display_name).is_equal("Hand Axe")
	var magic := roller.roll_item(axe, Item.Rarity.MAGIC, 1)
	var prefix := ItemLibrary.affix(magic.affixes[0].id).prefix
	assert_str(magic.display_name).is_equal("%s Hand Axe" % prefix)
	assert_str(roller.roll_item(axe, Item.Rarity.RARE, 1).display_name).is_not_equal("Hand Axe")

func test_drop_chance_zero_drops_nothing() -> void:
	var drops := _roller().roll_drops(_table(0.0), 1)
	assert_int(drops.items.size()).is_equal(0)
	assert_int(drops.gold).is_equal(0)

func test_gold_rolls_in_range_and_gold_find_adds_to_it() -> void:
	var table := _table(0.0)
	table.gold_chance = 1.0
	table.gold_min = 10
	table.gold_max = 10
	assert_int(_roller().roll_drops(table, 1).gold).is_equal(10)
	assert_int(_roller().roll_drops(table, 1, 0.0, 0.5).gold).is_equal(15)

func test_bonus_rolls_add_drops() -> void:
	var drops := _roller().roll_drops(_table(), 1, 0.0, 0.0, "", 2)
	assert_int(drops.items.size()).is_equal(3)

func test_elites_and_bosses_roll_more_and_better() -> void:
	var table := _table(0.0)
	table.rarity_weights = {0: 100, 1: 10, 2: 1, 3: 0}
	var plain := LootDropper.boost(false, false)
	var elite := LootDropper.boost(false, true)
	var boss := LootDropper.boost(true, false)
	var normal_drops := _roller().roll_drops(table, 1, plain.magic_find, 0.0, "", plain.rolls, plain.min_rarity)
	var elite_drops := _roller().roll_drops(table, 1, elite.magic_find, 0.0, "", elite.rolls, elite.min_rarity)
	var boss_drops := _roller().roll_drops(table, 1, boss.magic_find, 0.0, "", boss.rolls, boss.min_rarity)
	assert_int(normal_drops.items.size()).is_equal(0)
	assert_int(elite_drops.items.size()).is_equal(2)
	assert_int(boss_drops.items.size()).is_greater(elite_drops.items.size())
	for item: Item in elite_drops.items:
		assert_int(item.rarity).is_greater_equal(Item.Rarity.MAGIC)
	for item: Item in boss_drops.items:
		assert_int(item.rarity).is_greater_equal(Item.Rarity.RARE)
