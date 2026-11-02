class_name ItemCard
extends PanelContainer
# An item's details, D3 style: name in its rarity colour, what kind of thing it is, its stats, and -
# when it's not being worn - what wearing it would gain (green) or lose (red) over what is.

const BETTER := Color("7fc46a")
const WORSE := Color("d9573f")
const AFFIX := Color("8fa3ff")
const KIND_NAMES := {
	"axe": "Axe", "sword": "Sword", "dagger": "Dagger", "staff": "Staff", "wand": "Wand",
	"shield": "Shield", "tome": "Tome", "helm": "Helm", "chest": "Chest Armour", "gloves": "Gloves",
	"boots": "Boots", "ring": "Ring", "amulet": "Amulet",
}
const RARITY_NAMES := ["", "Magic", "Rare", "Legendary"]

var _rows := VBoxContainer.new()

func _init(width := 520.0) -> void:
	custom_minimum_size.x = width
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := UiTheme.panel()
	box.set_content_margin_all(26)
	add_theme_stylebox_override("panel", box)
	_rows.add_theme_constant_override("separation", 4)
	add_child(_rows)

static func type_line(item: Item) -> String:
	var words := PackedStringArray()
	if item.rarity > Item.Rarity.NORMAL:
		words.append(RARITY_NAMES[item.rarity])
	if item.base.two_handed:
		words.append("Two-Handed")
	words.append(KIND_NAMES.get(item.base.kind, item.base.display_name))
	return " ".join(words)

# worn: what it would replace (ItemCompare.replaced); equipped: it's on the hero now
func show_item(item: Item, worn: Array[Item], class_id: String, equipped := false) -> void:
	for child in _rows.get_children():
		child.free()
	var name_label := UiTheme.heading(item.display_name, 36, item.colour())
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rows.add_child(name_label)
	_add(type_line(item), 24, UiTheme.FADED)
	if equipped:
		_add("Equipped", 22, UiTheme.GOLD)
	_rows.add_child(_rule())
	for stat: StringName in item.base.base_stats:
		_add(StatText.line(stat, float(item.base.base_stats[stat]), 0.0, false), 30, UiTheme.PARCHMENT)
	for rolled in item.affixes:
		var affix := ItemLibrary.affix(rolled.id)
		if affix:
			_add(StatText.line(affix.stat, 0.0 if affix.percent else rolled.value, rolled.value if affix.percent else 0.0), 26, AFFIX)
	if not item.base.can_be_worn_by(class_id):
		_add("%s only" % " / ".join(Array(item.base.classes).map(func(c: String) -> String: return c.capitalize())), 24, WORSE)
	elif not equipped:
		_rows.add_child(_rule())
		_add("If equipped", 22, UiTheme.FADED)
		var deltas := ItemCompare.deltas(item, worn)
		if worn.is_empty():
			# Every line above is a gain; no need to list them twice
			_add("Fills an empty slot", 26, BETTER)
			deltas.clear()
		elif deltas.is_empty():
			_add("No change", 24, UiTheme.FADED)
		for delta in deltas:
			_add(delta.text, 26, BETTER if delta.better else WORSE)
	_add("Item Level %d" % item.item_level, 20, UiTheme.DISABLED)

func lines() -> PackedStringArray:
	var found := PackedStringArray()
	for child in _rows.get_children():
		if child is Label:
			found.append(child.text)
	return found

func _add(words: String, font_size: int, colour: Color) -> Label:
	var label := UiTheme.text(words, font_size, colour)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rows.add_child(label)
	return label

func _rule() -> Control:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	gap.draw.connect(func() -> void:
		gap.draw_line(Vector2(0, 5), Vector2(gap.size.x, 5), Color(UiTheme.BRONZE, 0.6), 1.0))
	return gap
