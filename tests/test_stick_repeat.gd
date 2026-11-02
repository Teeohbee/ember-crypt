extends GdUnitTestSuite
# The left stick steps through menus like a held D-pad: once on the push, then repeating after a pause.

func test_a_push_presses_once_straight_away() -> void:
	var stick := StickRepeat.new()
	assert_that(stick.update(Vector2i.DOWN, 0.016)).is_equal(Vector2i.DOWN)
	assert_that(stick.update(Vector2i.DOWN, 0.016)).is_equal(Vector2i.ZERO)

func test_holding_repeats_after_the_first_delay() -> void:
	var stick := StickRepeat.new()
	stick.update(Vector2i.DOWN, 0.016)
	assert_that(stick.update(Vector2i.DOWN, StickRepeat.FIRST_DELAY - 0.05)).is_equal(Vector2i.ZERO)
	assert_that(stick.update(Vector2i.DOWN, 0.06)).is_equal(Vector2i.DOWN)
	assert_that(stick.update(Vector2i.DOWN, StickRepeat.REPEAT_EVERY)).is_equal(Vector2i.DOWN)

func test_letting_go_and_pushing_again_presses_again() -> void:
	var stick := StickRepeat.new()
	stick.update(Vector2i.DOWN, 0.016)
	stick.update(Vector2i.ZERO, 0.016)
	assert_that(stick.update(Vector2i.DOWN, 0.016)).is_equal(Vector2i.DOWN)

func test_changing_direction_presses_straight_away() -> void:
	var stick := StickRepeat.new()
	stick.update(Vector2i.DOWN, 0.016)
	assert_that(stick.update(Vector2i.RIGHT, 0.016)).is_equal(Vector2i.RIGHT)

func test_the_stronger_axis_wins_and_a_light_touch_is_nothing() -> void:
	assert_that(StickRepeat.direction_of(Vector2(0.9, 0.3))).is_equal(Vector2i.RIGHT)
	assert_that(StickRepeat.direction_of(Vector2(-0.2, -0.8))).is_equal(Vector2i.UP)
	assert_that(StickRepeat.direction_of(Vector2(0.3, 0.2))).is_equal(Vector2i.ZERO)
