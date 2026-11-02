class_name ItemLibrary
# Finds item bases and affixes by id: res://src/items/bases/<id>.tres and res://src/items/affixes/<id>.tres.

const BASES_DIR := "res://src/items/bases/"
const AFFIXES_DIR := "res://src/items/affixes/"

static func base(id: StringName) -> ItemBase:
	return _load(BASES_DIR, id)

static func affix(id: StringName) -> AffixDef:
	return _load(AFFIXES_DIR, id)

# Every base and affix, loaded once. list_directory copes with exported (remapped) builds.
static var _bases: Array[ItemBase] = []
static var _affixes: Array[AffixDef] = []

static func all_bases() -> Array[ItemBase]:
	if _bases.is_empty():
		_bases.assign(_load_all(BASES_DIR))
	return _bases

static func all_affixes() -> Array[AffixDef]:
	if _affixes.is_empty():
		_affixes.assign(_load_all(AFFIXES_DIR))
	return _affixes

static func _load_all(dir: String) -> Array:
	var found := []
	for file in ResourceLoader.list_directory(dir):
		if file.ends_with(".tres"):
			found.append(load(dir + file))
	return found

static func _load(dir: String, id: StringName) -> Resource:
	var path := dir + String(id) + ".tres"
	return load(path) if ResourceLoader.exists(path) else null
