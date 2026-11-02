extends ScreenSuite
# Select opens the bags over a paused world; A wears and takes off, X drops, focus crosses between
# the paper doll and the bags, and B closes it again.

const GAME := "res://src/game/game.tscn"

func _item(base_id: StringName) -> Item:
	var item := Item.new()
	item.base = ItemLibrary.base(base_id)
	item.display_name = item.base.display_name
	return item

func test_the_inventory_wears_drops_and_closes_on_the_pad() -> void:
	var game: Node = await open_screen(GAME)
	var hero: Hero = game.hero
	var screen: InventoryScreen = game.get_node("Inventory0")
	var axe := _item(&"hand_axe")
	var ring := _item(&"ring")
	hero.inventory.add(axe)
	hero.inventory.add(ring)
	await press("inventory")
	assert_bool(screen.is_open).is_true()
	assert_bool(get_tree().paused).is_true()
	assert_object(focused()).is_same(screen.bag[0])
	assert_bool(Array(screen.card.lines()).has("Hand Axe")).is_true()
	# A on the hand axe: it goes on, the great axe comes back to the bags
	await press("ui_accept")
	assert_object(hero.equipment.item_in(ItemBase.Slot.WEAPON)).is_same(axe)
	assert_str(String(hero.inventory.items[1].base.id)).is_equal("great_axe")
	# Left from the bags lands on the paper doll
	await press("ui_left")
	assert_int(screen.doll.find(focused())).is_greater_equal(0)
	await press("ui_right")
	# X drops the ring at the hero's feet
	await press("ui_right")
	assert_object(screen.bag[1].item).is_not_null()
	var before := FloorDrop.live.size()
	await press("skill_2")
	assert_int(FloorDrop.live.size()).is_equal(before + 1)
	assert_int(hero.inventory.items.size()).is_equal(1)
	await press("ui_cancel")
	assert_bool(screen.is_open).is_false()
	assert_bool(get_tree().paused).is_false()
