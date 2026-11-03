extends GdUnitTestSuite
# Hit feel: hit-stop, shake, damage numbers, flashes, knockback and bone bursts. Time is stepped by
# hand, never waited for.

const MINION := preload("res://src/monsters/defs/skeleton_minion.tres")

func after_test() -> void:
	Feedback.reset()

func test_hit_stop_slows_time_then_restores_it() -> void:
	var before := Engine.time_scale
	Feedback.hit_stop(0.1)
	assert_float(Engine.time_scale).is_equal_approx(before * Feedback.STOP_SCALE, 0.0001)
	# Game time runs at STOP_SCALE during the stop, so 0.1 s of stop is 0.005 s of stepped time
	Feedback._process(0.004)
	assert_bool(Feedback.stopped).is_true()
	Feedback._process(0.0011)
	assert_bool(Feedback.stopped).is_false()
	assert_float(Engine.time_scale).is_equal_approx(before, 0.0001)

func test_overlapping_hit_stops_keep_the_longer_and_restore_once() -> void:
	var before := Engine.time_scale
	Feedback.hit_stop(0.1)
	Feedback.hit_stop(0.04)
	assert_float(Engine.time_scale).is_equal_approx(before * Feedback.STOP_SCALE, 0.0001)
	Feedback._process(0.003)
	assert_bool(Feedback.stopped).is_true()
	Feedback._process(0.003)
	assert_float(Engine.time_scale).is_equal_approx(before, 0.0001)

func test_shake_builds_caps_and_decays() -> void:
	Feedback.shake(0.7)
	Feedback.shake(0.7)
	assert_float(Feedback.trauma).is_equal(1.0)
	Feedback._process(0.25)
	assert_float(Feedback.trauma).is_less(1.0)
	Feedback._process(5.0)
	assert_float(Feedback.trauma).is_equal(0.0)

func test_damage_numbers_rise_fade_and_go_back_to_the_pool() -> void:
	var numbers: DamageNumbers = auto_free(DamageNumbers.new())
	add_child(numbers)
	var label := numbers.show_number(Vector3(1, 2, 3), "12", Color.WHITE)
	assert_str(label.text).is_equal("12")
	numbers._process(DamageNumbers.LIFE * 0.5)
	assert_float(label.global_position.y).is_greater(2.5)
	assert_bool(label.visible).is_true()
	numbers._process(DamageNumbers.LIFE)
	assert_bool(label.visible).is_false()

func test_damage_numbers_never_grow_past_the_pool() -> void:
	var numbers: DamageNumbers = auto_free(DamageNumbers.new())
	add_child(numbers)
	for i in DamageNumbers.POOL * 2:
		numbers.show_number(Vector3.ZERO, str(i), Color.WHITE)
	assert_int(numbers.get_child_count()).is_equal(DamageNumbers.POOL)
	assert_int(numbers.active_count()).is_equal(DamageNumbers.POOL)

func test_a_hit_flashes_and_squashes_the_target_then_lets_go() -> void:
	var flashes: HitFlash = auto_free(HitFlash.new())
	add_child(flashes)
	var monster := _monster(Vector3.ZERO)
	flashes.flash(monster)
	var mesh: MeshInstance3D = HitFlash.meshes_of(monster)[0]
	assert_object(mesh.material_overlay).is_same(HitFlash.overlay())
	assert_float(monster.model.scale.y).is_less(MINION.scale)
	flashes._process(HitFlash.SECONDS + 0.01)
	assert_object(mesh.material_overlay).is_null()
	assert_bool(flashes.flashing(monster)).is_false()
	assert_vector(monster.model.scale).is_equal_approx(Vector3.ONE * MINION.scale, Vector3.ONE * 0.001)

func test_a_shove_slides_the_body_the_whole_way() -> void:
	var monster := _monster(Vector3.ZERO)
	var shove := Shove.apply(monster, Vector3(2, 0, 0), 0.2)
	for i in 20:
		shove._physics_process(1.0 / 60.0)
	assert_bool(shove.moving()).is_false()
	assert_float(monster.global_position.x).is_equal_approx(2.0, 0.01)

func test_bones_burst_up_and_come_to_rest_on_the_floor() -> void:
	var burst: BoneBurst = auto_free(BoneBurst.new())
	add_child(burst)
	burst.burst(Vector3(0, 0, 0), Vector3.FORWARD)
	burst._physics_process(0.1)
	var highest := 0.0
	for piece in burst.pieces:
		highest = maxf(highest, piece.position.y)
	assert_float(highest).is_greater(0.8)
	for i in 90:
		burst._physics_process(1.0 / 60.0)
	for piece in burst.pieces:
		assert_float(piece.position.y).is_between(0.0, 0.2)
	for i in 240:
		burst._physics_process(1.0 / 60.0)
	assert_bool(burst.running).is_false()

func test_a_hit_on_a_monster_pops_its_number_and_knocks_it_back() -> void:
	var hero := _hero(Vector3.ZERO)
	var monster := _monster(Vector3(0, 0, -2))
	var event := DamageEvent.new()
	event.source = hero
	event.target = monster
	event.amount = 7.0
	event.knockback = 1.5
	Feedback.hit(event)
	var shown := Feedback.numbers.labels.filter(func(label: Label3D) -> bool: return label.visible and label.text == "7")
	assert_int(shown.size()).is_equal(1)
	assert_bool(Feedback.flashes.flashing(monster)).is_true()
	var shove: Shove = monster.get_node("Shove")
	for i in 30:
		shove._physics_process(1.0 / 60.0)
	assert_float(monster.global_position.z).is_equal_approx(-3.5, 0.05)

func test_a_blow_on_a_monster_throws_sparks_from_it_and_reuses_them() -> void:
	var hero := _hero(Vector3.ZERO)
	var monster := _monster(Vector3(0, 0, -2))
	var event := DamageEvent.new()
	event.source = hero
	event.target = monster
	event.amount = 7.0
	Feedback.hit(event)
	var lit := Feedback.sparks.pool.filter(func(spray: GPUParticles3D) -> bool: return spray.emitting)
	assert_int(lit.size()).is_equal(1)
	assert_float(lit[0].global_position.distance_to(monster.global_position)).is_less(1.6)
	for i in HitSparks.POOL * 2:
		Feedback.hit(event)
	assert_int(Feedback.sparks.pool.size()).is_equal(HitSparks.POOL)

func test_a_dead_monster_bursts_into_bones() -> void:
	var monster := _monster(Vector3(3, 0, 0))
	var event := DamageEvent.new()
	event.target = monster
	event.amount = 1000.0
	monster.take_hit(event)
	var running := Feedback.bursts.filter(func(burst: BoneBurst) -> bool: return burst.running)
	assert_int(running.size()).is_equal(1)

func test_rolling_heroes_evade_hits() -> void:
	var hero := _hero(Vector3.ZERO)
	var monster := _monster(Vector3(0, 0, -2))
	hero.invulnerable = true
	assert_object(Combat.hit(monster, hero, null, 5.0)).is_null()
	assert_float(hero.health).is_equal(hero.max_health())

func _monster(at: Vector3) -> Monster:
	var monster: Monster = auto_free(Monster.new(MINION))
	monster.position = at
	add_child(monster)
	return monster

func _hero(at: Vector3) -> Hero:
	var hero: Hero = auto_free(Hero.new(Session.CLASSES[0], PlayerSlot.new(3)))
	hero.position = at
	add_child(hero)
	return hero
