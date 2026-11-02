extends GdUnitTestSuite
# Runes: a rune changes a copy of its skill (multiplying numbers, overriding fields, merging params)
# and never the skill itself, and every rune on disk belongs to a skill and changes something real.

func _skill() -> SkillDef:
	var skill := SkillDef.new()
	skill.id = &"bash"
	skill.damage_multiplier = 2.0
	skill.cooldown = 4.0
	skill.params = {"speed": 10.0, "count": 1}
	return skill

func test_a_rune_multiplies_overrides_and_merges_params_on_a_copy() -> void:
	var rune := RuneDef.new()
	rune.id = &"bash_fire"
	rune.multiply = {"damage_multiplier": 1.5, "cooldown": 0.5}
	rune.overrides = {"damage_kind": DamageEvent.Kind.FIRE}
	rune.params = {"count": 3}
	var skill := _skill()
	var runed := rune.apply(skill)
	assert_object(runed).is_not_same(skill)
	assert_float(runed.damage_multiplier).is_equal(3.0)
	assert_float(runed.cooldown).is_equal(2.0)
	assert_int(runed.damage_kind).is_equal(DamageEvent.Kind.FIRE)
	assert_int(runed.params.count).is_equal(3)
	assert_float(runed.params.speed).is_equal(10.0)
	assert_str(String(runed.id)).is_equal("bash")

func test_the_runed_copy_names_its_rune_for_effects_to_read() -> void:
	var rune := RuneDef.new()
	rune.id = &"bash_fire"
	assert_str(String(rune.apply(_skill()).params.rune)).is_equal("bash_fire")

func test_the_original_skill_is_untouched() -> void:
	var rune := RuneDef.new()
	rune.multiply = {"damage_multiplier": 10.0}
	rune.params = {"count": 9}
	var skill := _skill()
	rune.apply(skill)
	assert_float(skill.damage_multiplier).is_equal(2.0)
	assert_int(skill.params.count).is_equal(1)
	assert_bool(skill.params.has("rune")).is_false()

func test_the_library_finds_a_skills_runes_in_unlock_order() -> void:
	var runes := RuneLibrary.runes_for(&"bash")
	assert_int(runes.size()).is_greater(0)
	for i in runes.size() - 1:
		assert_int(runes[i].unlock_level).is_less_equal(runes[i + 1].unlock_level)
	assert_object(RuneLibrary.rune(&"bash", runes[0].id)).is_same(runes[0])
	assert_object(RuneLibrary.rune(&"bash", &"no_such_rune")).is_null()
	assert_array(RuneLibrary.runes_for(&"no_such_skill")).is_empty()

func test_every_rune_on_disk_belongs_to_its_folder_and_changes_real_fields() -> void:
	var probe := SkillDef.new()
	var count := 0
	for skill_id in RuneLibrary.skill_ids():
		for rune in RuneLibrary.runes_for(skill_id):
			count += 1
			assert_str(String(rune.skill)).is_equal(String(skill_id))
			assert_str(rune.display_name).is_not_empty()
			assert_str(rune.description).is_not_empty()
			assert_bool(rune.multiply.is_empty() and rune.overrides.is_empty() and rune.params.is_empty()) \
				.override_failure_message("%s changes nothing" % rune.id).is_false()
			for field: String in rune.multiply.keys() + rune.overrides.keys():
				assert_bool(field in probe).override_failure_message("%s: no field %s" % [rune.id, field]).is_true()
			assert_int(rune.unlock_level).is_between(1, Levels.MAX_LEVEL)
	assert_int(count).is_greater_equal(16)
