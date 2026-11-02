extends GdUnitTestSuite
# What things cost and the rules of buying and selling: pure, no scene.

func _item(rarity := Item.Rarity.NORMAL, level := 1, affix_count := 0) -> Item:
	var base := ItemBase.new()
	base.id = &"test_axe"
	base.display_name = "Test Axe"
	var item := Item.new()
	item.base = base
	item.rarity = rarity
	item.item_level = level
	for i in affix_count:
		item.affixes.append({"id": &"none", "value": 1.0})
	return item

func test_better_rarer_and_higher_level_items_are_worth_more() -> void:
	var plain := Pricing.value(_item())
	assert_int(plain).is_greater(0)
	assert_int(Pricing.value(_item(Item.Rarity.MAGIC))).is_greater(plain)
	assert_int(Pricing.value(_item(Item.Rarity.RARE))).is_greater(Pricing.value(_item(Item.Rarity.MAGIC)))
	assert_int(Pricing.value(_item(Item.Rarity.LEGENDARY))).is_greater(Pricing.value(_item(Item.Rarity.RARE)))
	assert_int(Pricing.value(_item(Item.Rarity.NORMAL, 10))).is_greater(plain)
	assert_int(Pricing.value(_item(Item.Rarity.MAGIC, 1, 2))).is_greater(Pricing.value(_item(Item.Rarity.MAGIC)))

func test_the_merchant_buys_for_a_quarter_of_what_he_sells_for() -> void:
	var item := _item(Item.Rarity.RARE, 8)
	assert_int(Pricing.buy_price(item)).is_equal(Pricing.value(item))
	assert_int(Pricing.sell_price(item)).is_equal(Pricing.value(item) / 4)
	assert_int(Pricing.sell_price(_item())).is_greater_equal(1)

func test_buying_takes_the_gold_and_moves_the_item_to_the_bag() -> void:
	var vendor := Vendor.new()
	var item := _item()
	vendor.stock.append(item)
	var bag := Inventory.new(5)
	bag.add_gold(1000)
	assert_int(vendor.buy(item, bag)).is_equal(Vendor.Result.OK)
	assert_int(bag.gold).is_equal(1000 - Pricing.buy_price(item))
	assert_array(bag.items).contains_exactly([item])
	assert_array(vendor.stock).is_empty()

func test_you_cant_buy_what_you_cant_afford_or_carry() -> void:
	var vendor := Vendor.new()
	var item := _item()
	vendor.stock.append(item)
	var poor := Inventory.new(5)
	assert_int(vendor.buy(item, poor)).is_equal(Vendor.Result.TOO_POOR)
	var full := Inventory.new(0)
	full.add_gold(1000)
	assert_int(vendor.buy(item, full)).is_equal(Vendor.Result.BAG_FULL)
	assert_int(full.gold).is_equal(1000)
	assert_array(vendor.stock).contains_exactly([item])

func test_selling_pays_and_the_merchant_keeps_it_to_sell_back() -> void:
	var vendor := Vendor.new()
	var item := _item(Item.Rarity.MAGIC, 3)
	var bag := Inventory.new(5)
	bag.add(item)
	assert_int(vendor.sell(item, bag)).is_equal(Vendor.Result.OK)
	assert_int(bag.gold).is_equal(Pricing.sell_price(item))
	assert_array(bag.items).is_empty()
	assert_array(vendor.stock).contains([item])

func test_stock_is_normal_gear_the_hero_could_find_at_their_level() -> void:
	var low := ItemBase.new()
	low.id = &"low"
	var high := ItemBase.new()
	high.id = &"high"
	high.min_level = 20
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var stock := Vendor.roll_stock([low, high], 5, rng, 6)
	assert_int(stock.size()).is_equal(6)
	for item in stock:
		assert_str(item.base.id).is_equal("low")
		assert_int(item.item_level).is_equal(5)
		assert_int(item.rarity).is_equal(Item.Rarity.NORMAL)
