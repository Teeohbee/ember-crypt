class_name TradeScreen
extends WorldScreen
# Two item columns side by side and A to move the focused item across - the shape of both the stash
# and the vendor. Subclasses say what's in each column, what it costs and what A does. Underneath:
# the hero's gold, and a line about whatever has focus (or why that didn't work).

var left: ItemColumn
var right: ItemColumn
var gold_label := UiTheme.text("", 30, UiTheme.GOLD)
var details := UiTheme.text("", 26, UiTheme.FADED)

func _build() -> void:
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 48)
	columns.add_child(left)
	columns.add_child(right)
	body.add_child(columns)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 40)
	footer.add_child(gold_label)
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.custom_minimum_size.x = 700
	footer.add_child(details)
	body.add_child(footer)
	for column in [left, right]:
		column.chosen.connect(func(item: Item) -> void: _choose(column, item))
		column.focused.connect(func(item: Item) -> void: details.text = describe(item))
	refresh()
	if not left.focus_index(0):
		right.focus_index(0)

# Rebuilds both columns, keeping focus on the same row of the same column where it can
func refresh(keep: ItemColumn = null, row := 0) -> void:
	_fill()
	left.link(right, true)
	right.link(left, false)
	gold_label.text = "Gold  %d" % hero.inventory.gold
	if keep:
		var other := right if keep == left else left
		if not keep.focus_index(row):
			other.focus_index(row)

# Override: show_items on left and right
func _fill() -> void:
	pass

# Override: A on item in column. Return a message for a failure, or "" if it worked.
func _act(_column: ItemColumn, _item: Item) -> String:
	return ""

func _choose(column: ItemColumn, item: Item) -> void:
	var row := column.focused_index()
	var problem := _act(column, item)
	if problem != "":
		Sound.play("denied")
		details.text = problem
		return
	refresh(column, row)

# One line about an item: its slot, what it gives, and its level
static func describe(item: Item) -> String:
	var parts: Array[String] = [String(ItemBase.Slot.keys()[item.base.slot]).capitalize()]
	for stat: StringName in item.base.base_stats:
		parts.append("%s %s" % [_number(item.base.base_stats[stat]), String(stat).capitalize()])
	for rolled in item.affixes:
		var affix := ItemLibrary.affix(rolled.id)
		if affix:
			parts.append(affix.text % (rolled.value * 100.0 if affix.percent else rolled.value))
	parts.append("Level %d" % item.item_level)
	return "  -  ".join(parts)

static func _number(amount: float) -> String:
	return str(int(amount)) if is_equal_approx(amount, roundf(amount)) else "%.1f" % amount
