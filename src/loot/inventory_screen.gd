class_name InventoryScreen
extends CanvasLayer
# Select opens the hero's bags and paper doll. The world pauses behind it. Move around the squares
# on the stick or D-pad; the card on the right shows the item under focus and, for anything in the
# bags, what wearing it would change. A wears or takes off, X drops it on the floor, B or Select
# closes.

const DOLL_ORDER: Array[ItemBase.Slot] = [ItemBase.Slot.HEAD, ItemBase.Slot.WEAPON, ItemBase.Slot.CHEST,
	ItemBase.Slot.OFFHAND, ItemBase.Slot.HANDS, ItemBase.Slot.RING, ItemBase.Slot.FEET, ItemBase.Slot.AMULET]
const DOLL_COLUMNS := 2
const BAG_COLUMNS := 6
const SHEET: Array[StringName] = [Stats.DAMAGE, Stats.MAX_HEALTH, Stats.ARMOUR, Stats.RESIST, Stats.CRIT_CHANCE,
	Stats.CRIT_DAMAGE, Stats.ATTACK_SPEED, Stats.MAGIC_FIND]
const DROP := &"skill_2"

var slot: PlayerSlot
var is_open := false
var doll: Array[ItemSlot] = []
var bag: Array[ItemSlot] = []
var card := ItemCard.new(520)

var _root := Control.new()
var _title: Label
var _gold: Label
var _count: Label
var _sheet := GridContainer.new()
var _empty_note: Label
var _prompts: PromptBar
var _focused: ItemSlot

func _init(player_slot: PlayerSlot) -> void:
	slot = player_slot
	name = "Inventory%d" % player_slot.index
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var shade := ColorRect.new()
	shade.color = Color(UiTheme.VOID, 0.82)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(centre)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 28)
	centre.add_child(columns)
	columns.add_child(_doll_panel())
	columns.add_child(_bag_panel())
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 520
	right.add_child(card)
	_empty_note = UiTheme.text("", 26, UiTheme.FADED)
	right.add_child(_empty_note)
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(gap)
	var sheet_panel := PanelContainer.new()
	var sheet_rows := VBoxContainer.new()
	sheet_panel.add_child(sheet_rows)
	sheet_rows.add_child(UiTheme.heading("Character", 30, UiTheme.FADED))
	_sheet.columns = 2
	_sheet.add_theme_constant_override("h_separation", 24)
	sheet_rows.add_child(_sheet)
	right.add_child(sheet_panel)
	columns.add_child(right)
	_prompts = PromptBar.in_corner(_root)
	_link_focus()
	_root.hide()

func _doll_panel() -> Control:
	var panel := PanelContainer.new()
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 14)
	panel.add_child(rows)
	_title = UiTheme.heading("", 40)
	rows.add_child(_title)
	rows.add_child(UiTheme.divider(260))
	var grid := GridContainer.new()
	grid.columns = DOLL_COLUMNS
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rows.add_child(grid)
	for gear_slot in DOLL_ORDER:
		var square := ItemSlot.new(112, gear_slot)
		square.name = "Doll%s" % ItemBase.Slot.keys()[gear_slot].capitalize()
		_hook(square)
		grid.add_child(square)
		doll.append(square)
	return panel

func _bag_panel() -> Control:
	var panel := PanelContainer.new()
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 14)
	panel.add_child(rows)
	var top := HBoxContainer.new()
	top.add_child(UiTheme.heading("Bags", 40))
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(gap)
	_count = UiTheme.text("", 26, UiTheme.FADED)
	top.add_child(_count)
	rows.add_child(top)
	rows.add_child(UiTheme.divider(660))
	var grid := GridContainer.new()
	grid.columns = BAG_COLUMNS
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	rows.add_child(grid)
	var hero_bag := slot.hero.inventory if slot.hero else Inventory.new()
	for i in hero_bag.capacity:
		var square := ItemSlot.new(104)
		square.name = "Bag%d" % i
		_hook(square)
		grid.add_child(square)
		bag.append(square)
	_gold = UiTheme.text("", 30, FloorDrop.GOLD_COLOUR)
	rows.add_child(_gold)
	return panel

func _hook(square: ItemSlot) -> void:
	square.focus_entered.connect(func() -> void:
		if is_open and _focused != square:
			Sound.play("focus")
		_focused = square
		_show_focused())
	square.pressed.connect(func() -> void: _choose(square))

# Doll squares and bag squares as one grid, so left and right cross between them on any row
func _link_focus() -> void:
	var cells := {}
	for i in doll.size():
		cells[Vector2i(i % DOLL_COLUMNS, i / DOLL_COLUMNS)] = doll[i]
	for i in bag.size():
		cells[Vector2i(DOLL_COLUMNS + i % BAG_COLUMNS, i / BAG_COLUMNS)] = bag[i]
	var bottom := {}
	for cell: Vector2i in cells:
		bottom[cell.x] = maxi(bottom.get(cell.x, 0), cell.y)
	for cell: Vector2i in cells:
		var square: ItemSlot = cells[cell]
		var neighbours := {
			"focus_neighbor_top": cell + Vector2i.UP, "focus_neighbor_bottom": cell + Vector2i.DOWN,
			"focus_neighbor_left": cell + Vector2i.LEFT, "focus_neighbor_right": cell + Vector2i.RIGHT,
		}
		for side: String in neighbours:
			var to: Vector2i = neighbours[side]
			if bottom.has(to.x):
				to.y = mini(to.y, bottom[to.x])
			var target: ItemSlot = cells.get(to, square)
			square.set(side, square.get_path_to(target))

func _unhandled_input(event: InputEvent) -> void:
	if not is_open and event.is_action_pressed("inventory") and not get_tree().paused and slot.hero:
		get_viewport().set_input_as_handled()
		open()

# While open it hears its buttons before anything else, so Start can't pause underneath it
func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed("inventory") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()
	elif event.is_action_pressed(DROP):
		get_viewport().set_input_as_handled()
		drop_focused()

func open() -> void:
	is_open = true
	get_tree().paused = true
	Sound.play("open")
	refresh()
	_root.show()
	_root.modulate.a = 0.0
	create_tween().set_ignore_time_scale(true).tween_property(_root, "modulate:a", 1.0, 0.15)
	_focused = bag[0]
	bag[0].grab_focus()
	_show_focused()

func close() -> void:
	is_open = false
	Sound.play("back")
	get_tree().paused = false
	var focus := _root.get_viewport().gui_get_focus_owner()
	if focus:
		focus.release_focus()
	_root.hide()

func hero() -> Hero:
	return slot.hero

func refresh() -> void:
	var h := hero()
	_title.text = h.hero_class.display_name
	for square in doll:
		square.show_item(h.equipment.item_in(square.gear_slot))
	for i in bag.size():
		bag[i].show_item(h.inventory.items[i] if i < h.inventory.items.size() else null)
	_count.text = "%d / %d" % [h.inventory.items.size(), h.inventory.capacity]
	_gold.text = "%d Gold" % h.inventory.gold
	for child in _sheet.get_children():
		child.free()
	for stat in SHEET:
		_sheet.add_child(UiTheme.text(StatText.stat_name(stat), 22, UiTheme.FADED))
		_sheet.add_child(UiTheme.text(StatText.total(stat, h.stats.value(stat)), 22))
	_show_focused()

func _show_focused() -> void:
	if not is_open or _focused == null:
		return
	var h := hero()
	var item := _focused.item
	card.visible = item != null
	_empty_note.visible = item == null
	if item:
		var worn := _focused.gear_slot >= 0
		card.show_item(item, [] as Array[Item] if worn else ItemCompare.replaced(h.equipment, item), h.hero_class.id, worn)
		_prompts.show_prompts([["a", "Take Off" if worn else "Equip"], ["x", "Drop"], ["b", "Close"]])
	else:
		_empty_note.text = "Nothing worn here" if _focused.gear_slot >= 0 else "Empty"
		_prompts.show_prompts([["b", "Close"]])

func _choose(square: ItemSlot) -> void:
	if square.item == null:
		return
	var h := hero()
	var done := false
	if square.gear_slot >= 0:
		done = ItemSwap.unequip(square.gear_slot, h.equipment, h.inventory)
	else:
		done = ItemSwap.equip(square.item, h.equipment, h.inventory, h.hero_class.id)
	Sound.play("equip" if done else "denied")
	refresh()

# X: out of the bags (or off the hero) and onto the floor at their feet
func drop_focused() -> void:
	if _focused == null or _focused.item == null:
		return
	var h := hero()
	var item := _focused.item
	if _focused.gear_slot >= 0:
		h.equipment.unequip(_focused.gear_slot)
	else:
		h.inventory.remove(item)
	var angle := randf() * TAU
	var spot := h.global_position + Vector3(cos(angle), 0, sin(angle)) * 1.3
	FloorDrop.toss_item(h.get_parent(), item, h.global_position + Vector3.UP, spot, slot)
	Sound.play("pickup")
	refresh()
