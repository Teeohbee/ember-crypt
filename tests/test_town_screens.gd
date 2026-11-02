extends ScreenSuite
# The stash and the vendor, driven with the pad.

func _item(item_name: String) -> Item:
	var base := ItemBase.new()
	base.id = StringName(item_name.to_snake_case())
	base.display_name = item_name
	base.base_stats = {Stats.DAMAGE: 4.0}
	var item := Item.new()
	item.base = base
	item.display_name = item_name
	return item

func _open(screen: WorldScreen) -> Hero:
	var world: Node3D = auto_free(Node3D.new())
	get_tree().root.add_child(world)
	var hero := Hero.new(Session.CLASSES[0], PlayerSlot.new(3))
	world.add_child(hero)
	world.add_child(screen)
	screen.open(hero)
	await frames(1)
	return hero

func test_a_moves_items_between_bag_and_stash() -> void:
	var stash := Inventory.new(1)
	var screen := StashScreen.new(stash)
	var axe := _item("Hand Axe")
	var sword := _item("Short Sword")
	var hero: Hero = await _open(screen)
	hero.inventory.add(axe)
	hero.inventory.add(sword)
	screen.refresh(screen.left, 0)
	await frames(1)
	assert_object(focused()).is_same(screen.left.buttons[0])
	await press("ui_accept")
	assert_array(stash.items).contains_exactly([axe])
	assert_array(hero.inventory.items).contains_exactly([sword])
	# The stash only holds one: the next one stays put, and says why
	await press("ui_accept")
	assert_array(hero.inventory.items).contains_exactly([sword])
	assert_str(screen.details.text).is_equal("The stash is full.")
	await press("ui_right")
	assert_object(focused()).is_same(screen.right.buttons[0])
	await press("ui_accept")
	assert_array(stash.items).is_empty()
	assert_int(hero.inventory.items.size()).is_equal(2)
	await press("ui_cancel")
	await frames(2)
	assert_bool(get_tree().paused).is_false()

func test_a_buys_from_the_merchant_and_sells_to_him() -> void:
	var vendor := Vendor.new()
	var helm := _item("Iron Helm")
	vendor.stock.append(helm)
	var screen := VendorScreen.new(vendor)
	var hero: Hero = await _open(screen)
	hero.inventory.add_gold(500)
	screen.refresh(screen.left, 0)
	await frames(1)
	await press("ui_accept")
	assert_array(hero.inventory.items).contains_exactly([helm])
	assert_int(hero.inventory.gold).is_equal(500 - Pricing.buy_price(helm))
	assert_object(focused()).is_same(screen.right.buttons[0])
	await press("ui_accept")
	assert_array(hero.inventory.items).is_empty()
	assert_int(hero.inventory.gold).is_equal(500 - Pricing.buy_price(helm) + Pricing.sell_price(helm))
	assert_str(screen.gold_label.text).is_equal("Gold  %d" % hero.inventory.gold)
	await press("ui_cancel")
