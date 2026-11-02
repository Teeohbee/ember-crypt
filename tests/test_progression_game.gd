extends ScreenSuite
# Progression in the real game scene: the current character's hero arrives as they were saved, with an
# XP bar on the HUD, kills pay XP, and leaving the game writes them back.

const GAME := "res://src/game/game.tscn"

func after_test() -> void:
	Session.hero_class = Session.CLASSES[0]
	Session.zone_id = ""
	super()

func test_the_character_arrives_as_saved_earns_xp_and_is_saved_on_leaving() -> void:
	var record := SaveGame.create(Session.CLASSES[0])
	record.level = 5
	record.xp = 10
	var game: Node = await open_screen(GAME)
	var hero: Hero = game.hero
	assert_int(hero.level).is_equal(5)
	assert_object(game.huds[0].get_node("XpBar")).is_not_null()
	var monster: Monster = get_tree().get_nodes_in_group(&"monsters")[0]
	monster.take_hit(Combat.resolve(_lethal(monster), hero.stats, monster.stats, RandomNumberGenerator.new()))
	assert_int(hero.xp).is_greater(10)
	var earned := hero.xp
	game.free()
	SaveGame.load_from_disk()
	assert_int(SaveGame.characters[0].level).is_equal(5)
	assert_int(SaveGame.characters[0].xp).is_equal(earned)

func _lethal(monster: Monster) -> DamageEvent:
	var event := DamageEvent.new()
	event.target = monster
	event.kind = DamageEvent.Kind.ARCANE
	event.amount = 100000.0
	return event
