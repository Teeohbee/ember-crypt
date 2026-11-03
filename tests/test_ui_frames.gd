extends GdUnitTestSuite
# The Kenney frames: panels and slots wear them, and the textures are held, so a frame built in a
# _draw() still has its texture when the frame renders (else the border draws as a solid block).

func test_panels_wear_the_bronze_frame() -> void:
	var box := UiTheme.panel()
	assert_object(box).is_instanceof(StyleBoxTexture)
	assert_str(box.texture.resource_path).is_equal(UiTheme.PANEL_FRAME)

func test_a_slot_edge_draws_no_centre_so_the_fill_shows() -> void:
	assert_bool(UiTheme.slot_edge().draw_center).is_false()

func test_frame_textures_are_held_between_draws() -> void:
	assert_object(UiTheme.slot_edge().texture).is_same(UiTheme.slot_edge().texture)
	assert_object(UiTheme.panel().texture).is_same(UiTheme.panel().texture)
