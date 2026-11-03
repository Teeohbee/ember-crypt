class_name ItemSlot
extends Button
# One square in the bags or on the paper doll: the item's glyph framed in its rarity colour, or the
# slot's name faded when it's empty. Gold frame and a glow when it has focus.

# The fill stops short of the frame's notched corners
const EDGE_INSET := 4.0
const EMPTY_GLYPHS := {
	ItemBase.Slot.WEAPON: "sword", ItemBase.Slot.OFFHAND: "shield", ItemBase.Slot.HEAD: "helm",
	ItemBase.Slot.CHEST: "chest", ItemBase.Slot.HANDS: "gloves", ItemBase.Slot.FEET: "boots",
	ItemBase.Slot.RING: "ring", ItemBase.Slot.AMULET: "amulet",
}

var item: Item
# For paper doll squares, which slot this is; -1 in the bags
var gear_slot := -1

func _init(side := 104.0, doll_slot := -1) -> void:
	gear_slot = doll_slot
	custom_minimum_size = Vector2(side, side)
	focus_mode = Control.FOCUS_ALL
	var clear := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		add_theme_stylebox_override(state, clear)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)

func show_item(shown: Item) -> void:
	item = shown
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var lit := has_focus()
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(UiTheme.ASH, 0.9) if item else Color(UiTheme.VOID, 0.75)
	if lit:
		fill.shadow_color = Color(UiTheme.EMBER, 0.35)
		fill.shadow_size = 12
	draw_style_box(fill, rect.grow(-EDGE_INSET))
	var edge := UiTheme.slot_edge()
	edge.modulate_color = UiTheme.GOLD if lit else (Color(item.colour(), 0.8) if item else UiTheme.BRONZE)
	draw_style_box(edge, rect)
	var inner := rect.grow(-size.x * 0.16)
	if item:
		ItemIcon.paint(self, item.base.kind, inner, item.colour())
	elif gear_slot >= 0:
		ItemIcon.paint(self, EMPTY_GLYPHS[gear_slot], inner, Color(UiTheme.FADED, 0.3))
