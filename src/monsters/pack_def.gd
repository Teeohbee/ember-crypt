class_name PackDef
extends Resource
# A pack of monsters that spawn and fight together: who's in it, by MonsterDef id. A SpawnPoint with
# a pack spawns all of them; when one wakes, they all do. If it rolls elite, the first member leads.

@export var id: StringName
@export var display_name := ""
@export var members: Array[StringName] = []
