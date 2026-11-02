extends GdUnitTestSuite
# Leap and Teleport go where they're pointed, but never through a wall.

func _wall(at: Vector3) -> void:
	var body: StaticBody3D = auto_free(StaticBody3D.new())
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(10, 4, 1)
	shape.shape = box
	body.add_child(shape)
	body.position = at
	add_child(body)

func _caster() -> Combatant:
	var caster: Combatant = auto_free(Combatant.new())
	add_child(caster)
	return caster

func test_an_open_path_goes_all_the_way() -> void:
	var caster := _caster()
	var landing := SkillMotion.clear_path(caster, Vector3.ZERO, Vector3(0, 0, -8))
	assert_vector(landing).is_equal_approx(Vector3(0, 0, -8), Vector3.ONE * 0.01)

func test_a_wall_stops_you_short() -> void:
	var caster := _caster()
	_wall(Vector3(0, 0, -5))
	await get_tree().physics_frame
	var landing := SkillMotion.clear_path(caster, Vector3.ZERO, Vector3(0, 0, -8))
	assert_float(landing.z).is_between(-4.5, -3.5)

func test_monsters_in_the_way_dont_stop_you() -> void:
	var caster := _caster()
	var monster: Combatant = auto_free(Combatant.new())
	var shape := CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	shape.position.y = 0.9
	monster.add_child(shape)
	monster.position = Vector3(0, 0, -4)
	add_child(monster)
	await get_tree().physics_frame
	var landing := SkillMotion.clear_path(caster, Vector3.ZERO, Vector3(0, 0, -8))
	assert_float(landing.z).is_equal_approx(-8.0, 0.01)
