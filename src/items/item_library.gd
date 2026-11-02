class_name ItemLibrary
# Finds item bases and affixes by id: res://src/items/bases/<id>.tres and res://src/items/affixes/<id>.tres.

const BASES_DIR := "res://src/items/bases/"
const AFFIXES_DIR := "res://src/items/affixes/"

static func base(id: StringName) -> ItemBase:
	return _load(BASES_DIR, id)

static func affix(id: StringName) -> AffixDef:
	return _load(AFFIXES_DIR, id)

static func _load(dir: String, id: StringName) -> Resource:
	var path := dir + String(id) + ".tres"
	return load(path) if ResourceLoader.exists(path) else null
