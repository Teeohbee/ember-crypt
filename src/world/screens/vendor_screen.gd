class_name VendorScreen
extends TradeScreen
# The merchant: his shelf on the left at his price, your bag on the right at what he'll give. A buys
# or sells the focused item.

const PROBLEMS := {
	Vendor.Result.TOO_POOR: "You can't afford that.",
	Vendor.Result.BAG_FULL: "Your bag is full.",
	Vendor.Result.NOT_HERE: "That's gone.",
}

var vendor: Vendor

func _init(merchant: Vendor, merchant_name := "Merchant") -> void:
	super()
	vendor = merchant
	title = merchant_name
	name = "VendorScreen"
	left = ItemColumn.new("For Sale")
	right = ItemColumn.new("Your Bag")

func _fill() -> void:
	left.show_items(vendor.stock, Pricing.buy_price)
	right.show_items(hero.inventory.items, Pricing.sell_price)

func _prompts() -> Array:
	return [["a", "Buy / Sell"], ["b", "Close"]]

func _act(column: ItemColumn, item: Item) -> String:
	var result := vendor.buy(item, hero.inventory) if column == left else vendor.sell(item, hero.inventory)
	if result != Vendor.Result.OK:
		return PROBLEMS[result]
	Sound.play("coins")
	return ""
