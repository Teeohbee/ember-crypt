extends GdUnitTestSuite
# SaveGame: characters are created, saved and listed; a hero's level, XP, runes, bags, gear and zone
# come back exactly; broken or unknown data never stops the game; and nothing is written without a
# character to write.

const FIXTURE_DIR := "res://src/items/bases/"

var scratch_path := "user://test_characters_%d.json" % OS.get_process_id()
var fixture_id := "test_fixture_%d" % OS.get_process_id()
var _real_path: String
var _made_dir := false

func before() -> void:
	_made_dir = not DirAccess.dir_exists_absolute(FIXTURE_DIR)
	DirAccess.make_dir_recursive_absolute(FIXTURE_DIR)
	var base := ItemBase.new()
	base.id = StringName(fixture_id)
	base.display_name = "Test Axe"
	base.slot = ItemBase.Slot.WEAPON
	base.base_stats = {Stats.DAMAGE: 5.0}
	ResourceSaver.save(base, FIXTURE_DIR + fixture_id + ".tres")

func after() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(FIXTURE_DIR + fixture_id + ".tres"))
	if _made_dir:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(FIXTURE_DIR))

func before_test() -> void:
	_real_path = SaveGame.path
	SaveGame.path = scratch_path
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch_path))
	SaveGame.load_from_disk()

func after_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch_path))
	SaveGame.path = _real_path
	SaveGame.load_from_disk()
	Session.hero_class = Session.CLASSES[0]
	Session.zone_id = ""

func _write(contents: String) -> void:
	var file := FileAccess.open(scratch_path, FileAccess.WRITE)
	file.store_string(contents)
	file.close()
	SaveGame.load_from_disk()

func _hero() -> Hero:
	var hero: Hero = auto_free(Hero.new(Session.hero_class, PlayerSlot.new(0)))
	add_child(hero)
	return hero

func _axe() -> Item:
	return Item.from_dict({"base": fixture_id, "rarity": Item.Rarity.MAGIC, "item_level": 4, "name": "Keen Test Axe"})

func test_no_file_means_no_characters() -> void:
	assert_array(SaveGame.characters).is_empty()
	assert_bool(SaveGame.has_current()).is_false()

func test_a_new_character_is_saved_named_and_chosen() -> void:
	var record := SaveGame.create(Session.CLASSES[1])
	assert_str(record.name).is_not_empty()
	assert_str(record["class"]).is_equal("mage")
	assert_object(Session.hero_class).is_same(Session.CLASSES[1])
	SaveGame.load_from_disk()
	assert_int(SaveGame.characters.size()).is_equal(1)
	assert_str(SaveGame.characters[0].name).is_equal(record.name)

func test_names_are_not_repeated() -> void:
	var names := {}
	for i in 14:
		names[SaveGame.create(Session.CLASSES[0]).name] = true
	assert_int(names.size()).is_equal(14)

func test_a_hero_comes_back_exactly() -> void:
	SaveGame.create(Session.CLASSES[0])
	Session.zone_id = "crypt_depths"
	var hero := _hero()
	hero.progress.set_level(6, 33)
	hero.progress.runes[&"bash"] = &"bash_frenzy"
	hero.inventory.add_gold(250)
	hero.inventory.add(_axe())
	hero.equipment.equip(_axe())
	SaveGame.store(hero)
	hero.free()
	Session.zone_id = ""

	SaveGame.load_from_disk()
	Session.checkpoint = Vector3(4, 0, 4)
	SaveGame.choose(SaveGame.characters[0].id)
	assert_str(Session.zone_id).is_equal("crypt_depths")
	# A checkpoint from whatever was played before doesn't carry into the restored zone
	assert_vector(Session.checkpoint).is_equal(Vector3.INF)
	var again := _hero()
	assert_int(again.level).is_equal(6)
	assert_int(again.xp).is_equal(33)
	assert_int(again.inventory.gold).is_equal(250)
	assert_int(again.inventory.items.size()).is_equal(1)
	assert_str(again.inventory.items[0].display_name).is_equal("Keen Test Axe")
	assert_str(again.equipment.item_in(ItemBase.Slot.WEAPON).display_name).is_equal("Keen Test Axe")
	assert_float(again.health).is_equal_approx(again.max_health(), 0.001)

func test_runes_come_back() -> void:
	var hero_class: HeroClass = Session.CLASSES[0].duplicate()
	var bash := SkillDef.new()
	bash.id = &"bash"
	hero_class.skills = [bash]
	SaveGame.create(Session.CLASSES[0])
	Session.hero_class = hero_class
	var hero := _hero()
	hero.progress.set_level(5, 0)
	hero.progress.set_rune(&"bash", &"bash_frenzy")
	SaveGame.store(hero)
	hero.free()
	SaveGame.load_from_disk()
	SaveGame.choose(SaveGame.characters[0].id)
	Session.hero_class = hero_class
	assert_object(_hero().progress.rune_for(&"bash").id).is_equal(&"bash_frenzy")

func test_items_of_unknown_bases_are_dropped_not_fatal() -> void:
	var record := SaveGame.create(Session.CLASSES[0])
	record.inventory = {"gold": 5, "items": [{"base": "long_gone"}, _axe().to_dict()]}
	record.equipment = {"0": {"base": "long_gone"}}
	var hero := _hero()
	assert_int(hero.inventory.items.size()).is_equal(1)
	assert_int(hero.inventory.gold).is_equal(5)
	assert_object(hero.equipment.item_in(ItemBase.Slot.WEAPON)).is_null()

func test_a_broken_file_gives_no_characters() -> void:
	_write("{ not json")
	assert_array(SaveGame.characters).is_empty()

func test_records_of_unknown_classes_are_skipped() -> void:
	_write(JSON.stringify({"version": 1, "characters": [
		{"id": "a", "name": "Ghost", "class": "necromancer", "level": 3},
		{"id": "b", "name": "Brakka", "class": "barbarian", "level": "high"}]}))
	assert_int(SaveGame.characters.size()).is_equal(1)
	assert_str(SaveGame.characters[0].name).is_equal("Brakka")
	assert_int(SaveGame.characters[0].level).is_equal(1)

func test_last_played_is_the_most_recent() -> void:
	var first := SaveGame.create(Session.CLASSES[0])
	var second := SaveGame.create(Session.CLASSES[1])
	first.played = second.played + 10
	assert_str(SaveGame.last_played().id).is_equal(first.id)
	assert_str(SaveGame.sorted()[0].id).is_equal(first.id)

func test_deleting_a_character_sticks() -> void:
	var first := SaveGame.create(Session.CLASSES[0])
	var second := SaveGame.create(Session.CLASSES[1])
	SaveGame.delete(second.id)
	assert_bool(SaveGame.has_current()).is_false()
	SaveGame.load_from_disk()
	assert_int(SaveGame.characters.size()).is_equal(1)
	assert_str(SaveGame.characters[0].id).is_equal(first.id)

func test_nothing_is_written_without_a_character() -> void:
	var hero := _hero()
	SaveGame.store(hero)
	assert_bool(FileAccess.file_exists(scratch_path)).is_false()
