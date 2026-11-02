class_name MonsterLibrary
# Finds a MonsterDef by id: res://src/monsters/defs/<id>.tres.

const DEFS_DIR := "res://src/monsters/defs/"

static func find(id: StringName) -> MonsterDef:
	var path := DEFS_DIR + String(id) + ".tres"
	return load(path) if ResourceLoader.exists(path) else null

static func spawn(id: StringName, parent: Node3D, at: Vector3) -> Monster:
	var def := find(id)
	if def == null:
		push_error("No monster called %s" % id)
		return null
	var monster := Monster.new(def)
	parent.add_child(monster)
	monster.global_position = at
	return monster
