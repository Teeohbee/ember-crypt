extends GdUnitTestSuite
# The camera's polish: leaning ahead, shaking, and dissolving walls in the way. Stepped by hand.

func after_test() -> void:
	Feedback.reset()

func test_the_camera_leans_ahead_of_a_running_hero_but_not_too_far() -> void:
	assert_vector(GameCamera.lead_for(Vector3(4, 0, 0))).is_equal_approx(Vector3(1.2, 0, 0), Vector3.ONE * 0.001)
	assert_float(GameCamera.lead_for(Vector3(0, 0, -50)).length()).is_equal_approx(GameCamera.MAX_LEAD, 0.001)

func test_up_on_the_stick_runs_up_the_screen() -> void:
	var camera: GameCamera = auto_free(GameCamera.new())
	add_child(camera)
	camera.snap()
	var screen_up := -camera.global_basis.z
	screen_up.y = 0
	assert_float(GameCamera.ground(Vector2.UP).dot(screen_up.normalized())).is_greater(0.999)
	var screen_right := camera.global_basis.x
	assert_float(GameCamera.ground(Vector2.RIGHT).dot(screen_right)).is_greater(0.999)

func test_shake_moves_the_view_and_settles_back() -> void:
	var camera: GameCamera = auto_free(GameCamera.new())
	add_child(camera)
	var rest := camera.rotation
	Feedback.shake(1.0)
	camera._process(0.05)
	assert_float(absf(camera.h_offset) + absf(camera.v_offset)).is_greater(0.01)
	Feedback._process(5.0)
	camera._process(0.05)
	assert_float(camera.h_offset).is_equal(0.0)
	assert_vector(camera.rotation).is_equal_approx(rest, Vector3.ONE * 0.0001)

func test_a_wall_between_camera_and_hero_dissolves_then_comes_back() -> void:
	var fade: WallFade = auto_free(WallFade.new())
	add_child(fade)
	var wall: MeshInstance3D = auto_free(MeshInstance3D.new())
	var box := BoxMesh.new()
	box.size = Vector3(4, 4, 1)
	wall.mesh = box
	wall.position = Vector3(0, 2, 1.5)
	wall.add_to_group(WallFade.GROUP)
	add_child(wall)
	var aside: MeshInstance3D = auto_free(wall.duplicate())
	aside.position = Vector3(20, 2, 1.5)
	add_child(aside)
	var eye := Vector3(0, 11, 9.5)
	var hero: Array[Vector3] = [Vector3(0, 1.2, 0)]
	fade.check(eye, hero)
	fade.step(1.0)
	assert_float(fade.faded(wall)).is_equal(1.0)
	assert_object(wall.material_override).is_not_null()
	assert_float(fade.faded(aside)).is_equal(0.0)
	var moved: Array[Vector3] = [Vector3(0, 1.2, -10)]
	fade.check(Vector3(0, 11, -0.5), moved)
	fade.step(1.0)
	assert_float(fade.faded(wall)).is_equal(0.0)
	assert_object(wall.material_override).is_null()
