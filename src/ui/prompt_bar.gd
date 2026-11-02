class_name PromptBar
extends HBoxContainer
# The row of hints along the bottom of a screen: [A] Select  [B] Back. show_prompts() replaces them,
# so a screen can change its hints as its state changes.

func _init() -> void:
	add_theme_constant_override("separation", 34)
	alignment = BoxContainer.ALIGNMENT_END
	mouse_filter = Control.MOUSE_FILTER_IGNORE

# Pairs of [button, words], e.g. [["a", "Select"], ["b", "Back"]].
func show_prompts(prompts: Array) -> void:
	for child in get_children():
		child.queue_free()
	for prompt: Array in prompts:
		var pair := HBoxContainer.new()
		pair.add_theme_constant_override("separation", 10)
		pair.add_child(ButtonGlyph.new(prompt[0], 34))
		pair.add_child(UiTheme.text(prompt[1], 26, UiTheme.PARCHMENT))
		add_child(pair)

# Pinned to the bottom-right corner of `parent`, clear of the screen edge.
static func in_corner(parent: Control) -> PromptBar:
	var bar := PromptBar.new()
	parent.add_child(bar)
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_KEEP_SIZE, 56)
	bar.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	return bar
