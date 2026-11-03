extends GdUnitTestSuite
# Every hero skill has a picture, and the skill bar and skills screen show it.

func test_every_hero_skill_has_an_icon() -> void:
	for hero_class in Session.CLASSES:
		for skill in hero_class.skills:
			assert_object(skill.icon).override_failure_message("%s has no icon" % skill.id).is_not_null()

func test_the_skill_bar_socket_takes_the_icon() -> void:
	var skill: SkillDef = Session.CLASSES[0].skills[0]
	var slot: SkillSlot = auto_free(SkillSlot.new("a"))
	slot.show_skill(skill, 0.0, 0.0, true)
	assert_object(slot.icon).is_same(skill.icon)

func test_the_skills_screen_row_shows_the_icon() -> void:
	var hero: Hero = auto_free(Hero.new(Session.CLASSES[0], PlayerSlot.new(3)))
	add_child(hero)
	var skill: SkillDef = Session.CLASSES[0].skills[0]
	var row: SkillRow = auto_free(SkillRow.new(0, skill, hero.progress))
	var icon: TextureRect = row.find_child("Icon", true, false)
	assert_object(icon.texture).is_same(skill.icon)
