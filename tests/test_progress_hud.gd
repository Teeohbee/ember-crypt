extends GdUnitTestSuite
# The XP bar shows the hero's level, and a level-up raises a banner naming the level and what it
# unlocked, even when one kill jumps several levels.

func _hero() -> Hero:
	var hero_class: HeroClass = Session.CLASSES[0].duplicate()
	var bash := SkillDef.new()
	bash.id = &"bash"
	var cleave := SkillDef.new()
	cleave.id = &"cleave"
	cleave.display_name = "Cleave"
	cleave.unlock_level = 2
	hero_class.skills = [bash, cleave]
	var hero: Hero = auto_free(Hero.new(hero_class, PlayerSlot.new(6)))
	add_child(hero)
	return hero

func test_the_xp_bar_shows_the_level_and_follows_it() -> void:
	var hero := _hero()
	var bar: XpBar = auto_free(XpBar.new(hero.slot))
	add_child(bar)
	assert_str(bar.level_label.text).is_equal("1")
	hero.progress.gain_xp(Levels.xp_to_next(1) + Levels.xp_to_next(2))
	assert_str(bar.level_label.text).is_equal("3")

func test_a_level_up_raises_the_banner_with_its_unlocks() -> void:
	var hero := _hero()
	var banner: LevelBanner = auto_free(LevelBanner.new(hero.slot))
	add_child(banner)
	assert_bool(banner.visible).is_false()
	hero.progress.gain_xp(Levels.xp_to_next(1) + Levels.xp_to_next(2))
	assert_bool(banner.visible).is_true()
	assert_str(banner.title.text).is_equal("Level 3")
	var lines := banner.unlocks.get_children().filter(func(node: Node) -> bool: return not node.is_queued_for_deletion())
	# Both levels' unlocks, not just the last one's
	assert_array(lines.map(func(label: Label) -> String: return label.text)) \
		.contains_exactly(["New skill: Cleave", "New rune: Frenzy"])

func test_the_action_bar_shows_locked_skills_as_empty_sockets() -> void:
	var hero: Hero = auto_free(Hero.new(Session.CLASSES[1], PlayerSlot.new(6)))
	add_child(hero)
	var bar: ActionBar = auto_free(ActionBar.new(hero.slot))
	add_child(bar)
	bar.refresh()
	var locked: SkillDef = hero.hero_class.skills[2]
	assert_int(locked.unlock_level).is_greater(1)
	assert_bool(bar.skill_slots[2].empty).is_true()
	hero.progress.set_level(locked.unlock_level, 0)
	bar.refresh()
	assert_bool(bar.skill_slots[2].empty).is_false()
