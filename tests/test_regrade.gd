extends GdUnitTestSuite
# The KayKit regrade: bright colours lose their punch, skin keeps its warmth, and every live atlas has
# an untouched original to regrade from again.

const Regrade := preload("res://tools/regrade_kaykit.gd")

func _graded(colour: Color, drain := 0.45, tone := 0.22, dirt := 0.0) -> Color:
	var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.set_pixel(0, 0, colour)
	var grime := FastNoiseLite.new()
	Regrade.regrade(image, drain, tone, dirt, grime)
	return image.get_pixel(0, 0)

func test_a_toy_box_green_loses_most_of_its_colour() -> void:
	var green := Color(0.0, 0.6, 0.3)
	assert_float(_graded(green).s).is_less(green.s * 0.7)

func test_paint_white_is_knocked_back() -> void:
	assert_float(_graded(Color.WHITE).v).is_less(0.9)

func test_skin_keeps_its_warmth() -> void:
	var skin := Color8(247, 200, 166)
	assert_bool(Regrade.is_skin(skin)).is_true()
	assert_float(_graded(skin).s).is_greater(skin.s * 0.8)

func test_every_regraded_atlas_has_its_original() -> void:
	for atlas: String in Regrade.GRADES:
		assert_bool(FileAccess.file_exists(Regrade.ORIGINALS + atlas)).override_failure_message("%s has no original" % atlas).is_true()
