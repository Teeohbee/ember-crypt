extends ScreenSuite
# Loot in the game scene: kills drop it, it lands under a beam, A picks it up (unless a skeleton is
# close), gold is scooped by walking over it, and weapons show in the hero's hands. Time is stepped
# by hand: drops are landed with land(), the hero's physics is called directly.

const GAME := "res://src/game/game.tscn"
const STEP := 1.0 / 60.0

var game: Node
var hero: Hero

func before_test() -> void:
	super()
	game = await open_screen(GAME)
	hero = game.hero

func after_test() -> void:
	Input.action_release(&"skill_1")
	super()

func _clear_monsters() -> void:
	for monster in get_tree().get_nodes_in_group(&"monsters"):
		monster.remove_from_group(&"monsters")
		monster.queue_free()

func _item(base_id: StringName, rarity := Item.Rarity.NORMAL) -> Item:
	var item := Item.new()
	item.base = ItemLibrary.base(base_id)
	item.display_name = item.base.display_name
	item.rarity = rarity
	return item

func _drop_at_feet(item: Item) -> FloorDrop:
	var drop := FloorDrop.toss_item(game.zone, item, hero.global_position, hero.global_position + Vector3(1, 0, 0))
	drop.land()
	return drop

func test_a_kill_drops_loot_that_lands_under_a_beam() -> void:
	game.loot.default_table.drop_chance = 1.0
	game.loot.default_table.gold_chance = 1.0
	game.loot.default_table.rarity_weights = {0: 0, 1: 1, 2: 0, 3: 0}
	var dropped := []
	var count := func(item: Item, _at: Vector3, owner: PlayerSlot) -> void: dropped.append([item, owner])
	Events.item_dropped.connect(count)
	var monster: Monster = get_tree().get_nodes_in_group(&"monsters")[0]
	var blow := DamageEvent.new()
	blow.source = hero
	blow.amount = 9999.0
	monster.take_hit(blow)
	Events.item_dropped.disconnect(count)
	assert_int(dropped.size()).is_equal(1)
	assert_object(dropped[0][1]).is_same(hero.slot)
	assert_int(FloorDrop.live.size()).is_equal(2)
	for drop in FloorDrop.live:
		assert_bool(drop.landed).is_false()
		drop.land()
		assert_bool(drop.landed).is_true()
	var item_drop: FloorDrop = FloorDrop.live.filter(func(d: FloorDrop) -> bool: return not d.is_gold())[0]
	assert_object(item_drop.find_child("Beam", false, false)).is_not_null()

func test_a_picks_up_instead_of_attacking_when_nothing_hostile_is_close() -> void:
	_clear_monsters()
	await frames(1)
	var picked := []
	var on_pick := func(item: Item, by: Hero) -> void: picked.append([item, by])
	Events.item_picked_up.connect(on_pick)
	var item := _item(&"hand_axe", Item.Rarity.MAGIC)
	var drop := _drop_at_feet(item)
	Input.action_press(&"skill_1")
	hero._physics_process(STEP)
	Events.item_picked_up.disconnect(on_pick)
	assert_array(hero.inventory.items).contains_exactly([item])
	assert_int(picked.size()).is_equal(1)
	assert_bool(FloorDrop.live.has(drop)).is_false()
	# Still holding A: it doesn't turn into a swing
	assert_bool(hero.pickup.physics_step()).is_true()
	var popup: PickupPopup = game.huds[0].get_node("PickupPopup")
	assert_bool(popup.is_showing()).is_true()

func test_a_attacks_when_a_skeleton_is_close() -> void:
	var monster: Monster = get_tree().get_nodes_in_group(&"monsters")[0]
	monster.global_position = hero.global_position + Vector3(0, 0, -2)
	var drop := _drop_at_feet(_item(&"ring"))
	Input.action_press(&"skill_1")
	assert_bool(hero.pickup.physics_step()).is_false()
	assert_bool(FloorDrop.live.has(drop)).is_true()
	assert_bool(hero.inventory.items.is_empty()).is_true()

func test_walking_over_gold_scoops_it_up() -> void:
	var drop := FloorDrop.toss_gold(game.zone, 12, hero.global_position, hero.global_position + Vector3(0.5, 0, 0))
	drop.land()
	hero.pickup.physics_step()
	assert_int(hero.inventory.gold).is_equal(12)
	assert_bool(FloorDrop.live.has(drop)).is_false()

func test_holding_up_wears_what_was_just_picked_up() -> void:
	var popup: PickupPopup = game.huds[0].get_node("PickupPopup")
	var shield := _item(&"round_shield")
	hero.inventory.add(shield)
	popup.show_item(shield)
	assert_bool(Array(popup.card.lines()).has("+12 Armour")).is_true()
	Input.action_press(&"equip")
	popup._process(PickupPopup.HOLD_SECONDS * 0.5)
	assert_object(hero.equipment.item_in(ItemBase.Slot.OFFHAND)).is_null()
	popup._process(PickupPopup.HOLD_SECONDS * 0.6)
	Input.action_release(&"equip")
	assert_object(hero.equipment.item_in(ItemBase.Slot.OFFHAND)).is_same(shield)
	assert_bool(popup.is_showing()).is_false()
