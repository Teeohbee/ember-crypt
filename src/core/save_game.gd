extends Node
# The characters, saved to user://characters.json: each one's class, level, XP, runes, bags, gear and
# the zone they were in. One is current, the one being played; when its hero spawns it's restored from
# the record, and it's written back on level-ups, pickups, checkpoints, closing the skills screen and
# leaving the game. Like Settings, a missing or broken file never stops the game: unreadable records
# and items whose base no longer exists are dropped with a warning. path is swappable for tests.

const FORMAT_VERSION := 1

const NAMES := {
	"barbarian": ["Brakka", "Hrothgar", "Ulfa", "Kormak", "Sigrun", "Torvald", "Grimhild", "Bjorna", "Ragnor", "Asta"],
	"mage": ["Isolde", "Corvin", "Maelis", "Theron", "Ysolde", "Aldric", "Morwen", "Cassia", "Evander", "Sabine"],
}

var path := "user://characters.json"
var characters: Array[Dictionary] = []
var current_id := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_from_disk()
	Events.hero_spawned.connect(_on_hero_spawned)
	Events.hero_levelled_up.connect(func(hero: Hero, _level: int) -> void: store(hero))
	Events.item_picked_up.connect(func(_item: Item, hero: Hero) -> void: store(hero))
	Events.gold_picked_up.connect(func(_amount: int, hero: Hero) -> void: store(hero))
	Events.checkpoint_reached.connect(func(_checkpoint: Checkpoint, hero: Hero) -> void: store(hero))
	Events.zone_entered.connect(func(_zone: Zone) -> void:
		for hero in Session.heroes():
			store(hero))

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		for hero in Session.heroes():
			store(hero)

func has_current() -> bool:
	return not current().is_empty()

func current() -> Dictionary:
	return find(current_id)

func find(id: String) -> Dictionary:
	for record in characters:
		if record.id == id:
			return record
	return {}

# Most recently played first
func sorted() -> Array[Dictionary]:
	var list := characters.duplicate()
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.played > b.played)
	return list

func last_played() -> Dictionary:
	return {} if characters.is_empty() else sorted()[0]

static func class_of(record: Dictionary) -> HeroClass:
	for hero_class in Session.CLASSES:
		if hero_class.id == record.get("class"):
			return hero_class
	return null

# A fresh level 1 character, saved and made current
func create(hero_class: HeroClass) -> Dictionary:
	var record := {
		"id": "%d_%d" % [Time.get_unix_time_from_system(), randi()],
		"name": _new_name(hero_class.id),
		"class": hero_class.id,
		"level": 1, "xp": 0, "runes": {}, "inventory": {}, "equipment": {}, "zone": "town",
		"waypoints": ["town"], "dungeon_seed": 0,
		"played": _now(),
	}
	characters.append(record)
	choose(record.id)
	return record

# Makes a character current and sets Session up to play them: their class, their zone
func choose(id: String) -> void:
	var record := find(id)
	if record.is_empty():
		return
	current_id = id
	record.played = _now()
	Session.hero_class = class_of(record)
	Session.zone_id = record.zone
	Session.checkpoint = Vector3.INF
	Session.enter_world(record.waypoints, record.dungeon_seed)
	save_to_disk()

func delete(id: String) -> void:
	var record := find(id)
	if record.is_empty():
		return
	characters.erase(record)
	if current_id == id:
		current_id = ""
	save_to_disk()

# Writes the hero back into the current character and saves. Only player one's hero is a character
# until co-op; without a current character (tests, a dev run of the game scene) nothing is written.
func store(hero: Hero) -> void:
	var record := current()
	if record.is_empty() or not is_instance_valid(hero) or hero.slot.index != 0:
		return
	record.merge(hero.progress.to_dict(), true)
	record.inventory = hero.inventory.to_dict()
	record.equipment = hero.equipment.to_dict()
	record.zone = Session.zone_id
	record.waypoints = Session.waypoints.duplicate()
	record.dungeon_seed = Session.dungeon_seed
	record.played = _now()
	save_to_disk()

# Puts the current character onto a newly spawned hero: gear first, so the level's heal fills the
# health the gear gives
func restore(hero: Hero) -> void:
	var record := current()
	if record.is_empty():
		return
	var inventory: Dictionary = record.inventory.duplicate(true)
	inventory.items = _known_items(inventory.get("items", []))
	hero.inventory.load_dict(inventory)
	var equipment := {}
	for key: String in record.equipment:
		if not _known_items([record.equipment[key]]).is_empty():
			equipment[key] = record.equipment[key]
	hero.equipment.load_dict(equipment)
	hero.progress.load_dict(record)

func _on_hero_spawned(hero: Hero) -> void:
	if hero.slot.index != 0 or not has_current():
		return
	restore(hero)
	hero.tree_exiting.connect(store.bind(hero))

func load_from_disk() -> void:
	characters.clear()
	current_id = ""
	Session.stash.load_dict({})
	if not FileAccess.file_exists(path):
		return
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or not parser.data is Dictionary:
		push_warning("Characters file %s couldn't be read; starting with none" % path)
		return
	# M6: the town stash, shared by every character
	var stash: Variant = parser.data.get("stash")
	if stash is Dictionary:
		stash = stash.duplicate(true)
		stash.items = _known_items(stash.get("items", []))
		Session.stash.load_dict(stash)
	var saved: Variant = parser.data.get("characters", [])
	if not saved is Array:
		return
	for data: Variant in saved:
		var record := _clean(data)
		if record.is_empty():
			push_warning("Skipped an unreadable character in %s" % path)
		else:
			characters.append(record)

# Writes to a temporary file and swaps it in, so a crash mid-write can't leave half a file
func save_to_disk() -> void:
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		push_warning("Couldn't write characters file %s: %s" % [temporary, error_string(FileAccess.get_open_error())])
		return
	file.store_string(JSON.stringify({"version": FORMAT_VERSION, "characters": characters, "stash": Session.stash.to_dict()}, "\t"))
	file.close()
	var error := DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path))
	if error != OK:
		push_warning("Couldn't replace characters file %s: %s" % [path, error_string(error)])

# A record with every field present and of the right type, or {} if it can't be played
func _clean(data: Variant) -> Dictionary:
	if not data is Dictionary or not data.get("id") is String or class_of(data) == null:
		return {}
	var record := {
		"id": data.id,
		"name": data.get("name") if data.get("name") is String and data.name != "" else class_of(data).display_name,
		"class": data["class"],
		"level": clampi(_int(data.get("level"), 1), 1, Levels.MAX_LEVEL),
		"xp": maxi(_int(data.get("xp"), 0), 0),
		"zone": data.get("zone") if data.get("zone") is String else "",
		"played": _int(data.get("played"), 0),
	}
	for key in ["runes", "inventory", "equipment"]:
		record[key] = data.get(key) if data.get(key) is Dictionary else {}
	# M6: waypoints found and the crypt's seed
	var waypoints: Variant = data.get("waypoints")
	record.waypoints = waypoints.filter(func(id: Variant) -> bool: return id is String) if waypoints is Array else ["town"]
	record.dungeon_seed = _int(data.get("dungeon_seed"), 0)
	return record

func _known_items(list: Variant) -> Array:
	var known := []
	if not list is Array:
		return known
	for data: Variant in list:
		if data is Dictionary and data.get("base") is String and ItemLibrary.base(StringName(data.base)) != null:
			known.append(data)
		else:
			push_warning("Dropped a saved item whose base no longer exists: %s" % [data])
	return known

func _new_name(class_id: String) -> String:
	var taken := characters.map(func(record: Dictionary) -> String: return record.name)
	var pool: Array = NAMES.get(class_id, ["Wanderer"]).duplicate()
	pool.shuffle()
	for candidate: String in pool:
		if not candidate in taken:
			return candidate
	var number := 2
	while true:
		for candidate: String in pool:
			var numbered := "%s %s" % [candidate, _roman(number)]
			if not numbered in taken:
				return numbered
		number += 1
	return ""

static func _roman(number: int) -> String:
	var numerals := [[10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]
	var out := ""
	for pair: Array in numerals:
		while number >= pair[0]:
			out += pair[1]
			number -= pair[0]
	return out

# Seconds, with a counter so two saves in the same second still order correctly
var _tick := 0
func _now() -> int:
	_tick += 1
	return int(Time.get_unix_time_from_system()) * 1000 + _tick % 1000

static func _int(value: Variant, fallback: int) -> int:
	return int(value) if value is int or value is float else fallback
