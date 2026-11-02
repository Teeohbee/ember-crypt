extends ScreenSuite
# The game scene comes up with a hero on its feet, skeletons to fight, and the hero can kill one.

const GAME := "res://src/game/game.tscn"

func test_game_spawns_the_chosen_hero_and_monsters() -> void:
	var game: Node = await open_screen(GAME)
	assert_object(game.hero).is_not_null()
	assert_object(Session.slots[0].hero).is_same(game.hero)
	assert_int(get_tree().get_nodes_in_group(&"monsters").size()).is_greater(0)

func test_a_skill_hits_the_monster_in_front() -> void:
	var game: Node = await open_screen(GAME)
	var hero: Hero = game.hero
	var skill := SkillDef.new()
	skill.hit_time = 0.0
	skill.reach = 30.0
	skill.damage_multiplier = 100.0
	hero.skill_bar.set_skill(0, skill)
	var killed := []
	var count_kill := func(monster: Monster, _event: DamageEvent) -> void: killed.append(monster)
	Events.monster_killed.connect(count_kill)
	assert_bool(hero.skill_bar.use(0, Vector3.FORWARD)).is_true()
	await get_tree().process_frame
	Events.monster_killed.disconnect(count_kill)
	assert_int(killed.size()).is_equal(1)

func test_the_hud_shows_globes_and_skills_and_lb_drinks() -> void:
	var game: Node = await open_screen(GAME)
	var hero: Hero = game.hero
	var bar: ActionBar = game.huds[0].get_node("ActionBar")
	hero.health = hero.max_health() * 0.25
	await press("potion")
	assert_float(hero.health).is_greater(hero.max_health() * 0.5)
	assert_float(hero.potion.cooldown_left).is_greater(0.0)
	await frames(1)
	assert_float(bar.health_globe.fraction).is_equal_approx(hero.health / hero.max_health(), 0.01)
	assert_bool(bar.skill_slots[1].empty).is_false()
