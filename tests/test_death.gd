extends ScreenSuite
# Dying and coming back: the death screen comes up, A rises at the checkpoint at full health.

const GAME := "res://src/game/game.tscn"

var _checkpoint: Vector3

func before_test() -> void:
	super()
	_checkpoint = Session.checkpoint

func after_test() -> void:
	Session.checkpoint = _checkpoint
	super()

func test_a_dead_hero_rises_at_the_checkpoint() -> void:
	Session.checkpoint = Vector3(4, 0, 6)
	var game: Node = await open_screen(GAME)
	var hero: Hero = game.hero
	var screen: DeathScreen = game.huds[0].find_child("DeathScreen", false, false)
	screen.delay = 0.0
	var killer: Monster = get_tree().get_nodes_in_group(&"monsters")[0]
	var blow := DamageEvent.new()
	blow.source = killer
	blow.amount = 1.0e6
	hero.take_hit(blow)
	await frames(2)
	assert_bool(screen.is_open).is_true()
	assert_str(screen._killer.text).is_equal("Slain by a Skeleton Minion")
	assert_object(focused()).is_not_null()
	await press("ui_accept")
	assert_bool(hero.alive).is_true()
	assert_float(hero.health).is_equal(hero.max_health())
	assert_vector(hero.global_position).is_equal(Vector3(4, 0, 6))
	assert_bool(screen.is_open).is_false()

func test_a_death_with_no_killer_blames_the_dark() -> void:
	var event := DamageEvent.new()
	assert_str(DeathScreen.killer_name(event)).is_equal("the dark")
