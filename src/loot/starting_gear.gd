class_name StartingGear
# What a new hero walks in holding. Kept here rather than in the class .tres, which other milestones
# edit too. A loaded save replaces it (Equipment.load_dict takes everything off first).

const GEAR := {
	"barbarian": [[&"great_axe", "Notched Great Axe"]],
	"mage": [[&"staff", "Apprentice's Staff"]],
}

static func give(class_id: String, equipment: Equipment) -> void:
	for entry: Array in GEAR.get(class_id, []):
		var item := Item.new()
		item.base = ItemLibrary.base(entry[0])
		item.display_name = entry[1]
		equipment.equip(item)
