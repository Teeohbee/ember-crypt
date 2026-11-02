class_name Inventory
extends RefCounted
# A bag of items and a purse of gold. The hero's bags and the town stash are both one.

signal changed

var capacity := 30
var items: Array[Item] = []
var gold := 0

func _init(size := 30) -> void:
	capacity = size

func is_full() -> bool:
	return items.size() >= capacity

func add(item: Item) -> bool:
	if is_full():
		return false
	items.append(item)
	changed.emit()
	return true

func remove(item: Item) -> bool:
	var index := items.find(item)
	if index < 0:
		return false
	items.remove_at(index)
	changed.emit()
	return true

func add_gold(amount: int) -> void:
	gold += amount
	changed.emit()

func spend_gold(amount: int) -> bool:
	if amount > gold:
		return false
	gold -= amount
	changed.emit()
	return true

func to_dict() -> Dictionary:
	return {"capacity": capacity, "gold": gold, "items": items.map(func(item: Item) -> Dictionary: return item.to_dict())}

func load_dict(data: Dictionary) -> void:
	capacity = int(data.get("capacity", capacity))
	gold = int(data.get("gold", 0))
	items.clear()
	for item_data: Dictionary in data.get("items", []):
		items.append(Item.from_dict(item_data))
	changed.emit()
