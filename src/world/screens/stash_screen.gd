class_name StashScreen
extends TradeScreen
# The town chest: your bag on the left, the stash on the right, A moves the focused item across.

var stash: Inventory

func _init(chest: Inventory) -> void:
	super()
	stash = chest
	title = "Stash"
	name = "StashScreen"
	left = ItemColumn.new("Your Bag")
	right = ItemColumn.new("Stash")

func _fill() -> void:
	left.show_items(hero.inventory.items)
	right.show_items(stash.items)

func _prompts() -> Array:
	return [["a", "Move"], ["b", "Close"]]

func _act(column: ItemColumn, item: Item) -> String:
	var from := hero.inventory if column == left else stash
	var to := stash if column == left else hero.inventory
	if to.is_full():
		return "The stash is full." if to == stash else "Your bag is full."
	from.remove(item)
	to.add(item)
	Sound.play("stash")
	return ""
