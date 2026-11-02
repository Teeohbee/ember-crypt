class_name RuneLibrary
# Finds runes on disk: every RuneDef in res://src/skills/runes/<skill id>/, in unlock order. Adding a
# rune is adding a .tres there.

const DIR := "res://src/skills/runes/"

static var _cache := {}

static func skill_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for entry in ResourceLoader.list_directory(DIR):
		if entry.ends_with("/"):
			ids.append(StringName(entry.trim_suffix("/")))
	return ids

static func runes_for(skill_id: StringName) -> Array[RuneDef]:
	if not _cache.has(skill_id):
		var found: Array[RuneDef] = []
		var dir := DIR + String(skill_id) + "/"
		if DirAccess.dir_exists_absolute(dir):
			for entry in ResourceLoader.list_directory(dir):
				var loaded := load(dir + entry) if entry.ends_with(".tres") else null
				if loaded is RuneDef:
					found.append(loaded)
		found.sort_custom(func(a: RuneDef, b: RuneDef) -> bool:
			return a.unlock_level < b.unlock_level or (a.unlock_level == b.unlock_level and String(a.id) < String(b.id)))
		_cache[skill_id] = found
	return _cache[skill_id]

static func rune(skill_id: StringName, rune_id: StringName) -> RuneDef:
	for found in runes_for(skill_id):
		if found.id == rune_id:
			return found
	return null
