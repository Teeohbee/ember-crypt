class_name ActionBar
extends Control
# The bottom of the screen, D3 style: the health globe on the left, the power globe (Fury or Arcane,
# in the class's colour) on the right, and between them the potion on LB and a socket for each skill
# button. It reads its slot's hero every frame, so a respawned or swapped hero just shows up. Pressing
# a skill that's cooling down or can't be afforded shakes its socket with a dull knock.

const BUTTONS: Array[String] = ["a", "x", "y", "b", "rb", "rt"]
const MARGIN := 22.0

var slot: PlayerSlot
var health_globe := ResourceGlobe.new(Color(0.62, 0.07, 0.05), true)
var power_globe := ResourceGlobe.new(Color.WHITE)
var potion_slot := SkillSlot.new("lb")
var skill_slots: Array[SkillSlot] = []
var _hero: Hero

func _init(player_slot: PlayerSlot) -> void:
	slot = player_slot
	name = "ActionBar"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var row := HBoxContainer.new()
	row.name = "Row"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, MARGIN)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(row)
	row.add_child(health_globe)
	row.add_child(_gap(18))
	potion_slot.flask = true
	potion_slot.size_flags_vertical = Control.SIZE_SHRINK_END
	row.add_child(potion_slot)
	row.add_child(_gap(14))
	for button in BUTTONS:
		var socket := SkillSlot.new(button)
		socket.size_flags_vertical = Control.SIZE_SHRINK_END
		skill_slots.append(socket)
		row.add_child(socket)
	row.add_child(_gap(18))
	row.add_child(power_globe)
	potion_slot.show_skill(null, 0.0, 0.0, true)
	for socket in skill_slots:
		socket.show_skill(null, 0.0, 0.0, true)

func _gap(width: float) -> Control:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(width, 0)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return gap

func _process(_delta: float) -> void:
	refresh()
	_listen_for_denied()

func refresh() -> void:
	var hero := slot.hero if is_instance_valid(slot.hero) else null
	if hero != _hero:
		_watch(hero)
	if hero == null:
		health_globe.set_values(0.0, 0.0)
		power_globe.set_values(0.0, 0.0)
		return
	health_globe.set_values(hero.health, hero.max_health())
	power_globe.set_values(hero.power, hero.max_power())
	var bar := hero.skill_bar
	for i in skill_slots.size():
		var skill := bar.skills[i] if i < bar.skills.size() else null
		var affordable := skill == null or hero.power + 0.001 >= skill.cost
		skill_slots[i].show_skill(skill, bar.cooldown_fraction(i), bar.cooldown_left(i), affordable)
	potion_slot.show_skill(_potion_def(), hero.potion.cooldown_fraction(), hero.potion.cooldown_left, true)

func _watch(hero: Hero) -> void:
	if _hero and is_instance_valid(_hero) and _hero.skill_bar.used.is_connected(_on_used):
		_hero.skill_bar.used.disconnect(_on_used)
		_hero.potion.drunk.disconnect(_on_drunk)
	_hero = hero
	if hero == null:
		return
	power_globe.colour = hero.hero_class.power_colour
	hero.skill_bar.used.connect(_on_used)
	hero.potion.drunk.connect(_on_drunk)
	refresh_now.call_deferred()

func refresh_now() -> void:
	health_globe.snap()
	power_globe.snap()

func _on_used(index: int, _skill: SkillDef) -> void:
	if index < skill_slots.size():
		skill_slots[index].flash_used()

func _on_drunk(_amount: float) -> void:
	potion_slot.flash_used()

# A skill pressed that couldn't go off because it's cooling down or too dear: shake its socket
func _listen_for_denied() -> void:
	if _hero == null or not _hero.alive or _hero.skill_bar.busy:
		return
	var bar := _hero.skill_bar
	for i in Hero.SKILL_ACTIONS.size():
		var skill := bar.skills[i]
		if skill and slot.just_pressed(Hero.SKILL_ACTIONS[i]) and not bar.can_use(i):
			skill_slots[i].flash_denied()
			Sound.play("denied")

static var _potion: SkillDef

# The potion's socket shows a stand-in skill so it draws as filled
static func _potion_def() -> SkillDef:
	if _potion == null:
		_potion = SkillDef.new()
		_potion.display_name = "Health Potion"
		_potion.damage_kind = DamageEvent.Kind.FIRE
	return _potion
