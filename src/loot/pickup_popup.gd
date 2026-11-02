class_name PickupPopup
extends Control
# The D3 console pickup: whatever you pick up shows on the right for a few seconds with what it would
# change over your gear, and holding D-pad up wears it without opening a menu. Also the "[A] Pick up"
# hint under the hero when something's in reach, and the word when your bags are full.

const SHOW_SECONDS := 5.0
const HOLD_SECONDS := 0.6

var slot: PlayerSlot
var item: Item
var card := ItemCard.new(500)
var hint := HBoxContainer.new()
var _panel := VBoxContainer.new()
var _hold_row := HBoxContainer.new()
var _hold_bar := ProgressBar.new()
var _hint_text: Label
var _message: Label
var _left := 0.0
var _held := 0.0
var _message_left := 0.0
var _hero: Hero

func _init(player_slot: PlayerSlot) -> void:
	slot = player_slot
	name = "PickupPopup"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT, Control.PRESET_MODE_KEEP_SIZE, 60)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.add_theme_constant_override("separation", 10)
	add_child(_panel)
	_panel.add_child(card)
	_hold_row.add_theme_constant_override("separation", 12)
	_hold_row.add_child(ButtonGlyph.new("dpad", 36))
	_hold_row.add_child(UiTheme.text("Hold up to equip", 26))
	_hold_bar.custom_minimum_size = Vector2(160, 10)
	_hold_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hold_bar.show_percentage = false
	_hold_bar.max_value = HOLD_SECONDS
	var fill := StyleBoxFlat.new()
	fill.bg_color = UiTheme.GOLD
	var track := StyleBoxFlat.new()
	track.bg_color = Color(UiTheme.VOID, 0.8)
	track.border_color = UiTheme.BRONZE
	track.set_border_width_all(1)
	_hold_bar.add_theme_stylebox_override("fill", fill)
	_hold_bar.add_theme_stylebox_override("background", track)
	_hold_row.add_child(_hold_bar)
	_panel.add_child(_hold_row)
	_panel.hide()
	# Just below the hero, who's always mid-screen
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	hint.position.y += 110
	hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hint.add_theme_constant_override("separation", 10)
	hint.add_child(ButtonGlyph.new("a", 32))
	_hint_text = UiTheme.text("", 26)
	hint.add_child(_hint_text)
	add_child(hint)
	hint.hide()
	_message = UiTheme.text("", 28, ItemCard.WORSE)
	_message.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	_message.position.y += 160
	_message.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_message)
	_message.hide()
	Events.item_picked_up.connect(_on_picked_up)
	_hero = slot.hero
	if _hero:
		_hero.pickup.highlight_changed.connect(_on_highlight)
		_hero.pickup.bag_full.connect(func(_full: Item) -> void: say("Your bags are full"))

func _exit_tree() -> void:
	Events.item_picked_up.disconnect(_on_picked_up)

func _on_picked_up(picked: Item, by: Hero) -> void:
	if by == slot.hero:
		show_item(picked)

func show_item(shown: Item) -> void:
	item = shown
	var hero := slot.hero
	card.show_item(item, ItemCompare.replaced(hero.equipment, item), hero.hero_class.id)
	_hold_row.visible = item.base.can_be_worn_by(hero.hero_class.id)
	_left = SHOW_SECONDS
	_held = 0.0
	_hold_bar.value = 0.0
	_panel.modulate.a = 1.0
	_panel.show()

func is_showing() -> bool:
	return _panel.visible

func say(words: String) -> void:
	_message.text = words
	_message.show()
	_message_left = 2.0

func _on_highlight(drop: FloorDrop) -> void:
	hint.visible = drop != null
	if drop:
		_hint_text.text = "Pick up %s" % drop.item.display_name
		_hint_text.add_theme_color_override("font_color", drop.colour())

func _process(delta: float) -> void:
	if _message_left > 0.0:
		_message_left -= delta
		if _message_left <= 0.0:
			_message.hide()
	if not _panel.visible:
		return
	var hero := slot.hero
	# Worn, dropped or otherwise gone from the bags since: nothing left to show
	if not is_instance_valid(hero) or not hero.inventory.items.has(item):
		_panel.hide()
		return
	if _hold_row.visible and slot.pressed(&"equip"):
		_held += delta
		_hold_bar.value = _held
		if _held >= HOLD_SECONDS:
			_equip(hero)
		return
	_held = 0.0
	_hold_bar.value = 0.0
	_left -= delta
	_panel.modulate.a = clampf(_left / 0.4, 0.0, 1.0)
	if _left <= 0.0:
		_panel.hide()

func _equip(hero: Hero) -> void:
	_held = 0.0
	if ItemSwap.equip(item, hero.equipment, hero.inventory, hero.hero_class.id):
		Sound.play("equip")
		_panel.hide()
	else:
		Sound.play("denied")
		say("No room in your bags")
		_left = 0.0
		_panel.hide()
