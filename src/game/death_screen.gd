class_name DeathScreen
extends Control
# When a player's hero dies: the bell tolls, the world drains to a bloody dark, and after a moment
# "You Have Died" comes up with who did it and one choice, to rise again at the last checkpoint (or
# the zone's start if none was touched). B does nothing: there's nowhere to back out to.

# Seconds between the killing blow and the screen, so the death animation gets to play
const DELAY := 2.2
const FADE := 0.8
const BLOOD := Color("b3261e")

var slot: PlayerSlot
var zone: Zone
var delay := DELAY
var is_open := false

var _backdrop := ColorRect.new()
var _column := VBoxContainer.new()
var _killer := UiTheme.text("", 30, UiTheme.FADED)
var _menu := MenuList.new()
var _prompts: PromptBar
var _wait := -1.0
var _tween: Tween

func _init(player_slot: PlayerSlot, current_zone: Zone) -> void:
	name = "DeathScreen"
	slot = player_slot
	zone = current_zone
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	_backdrop.color = Color(0.09, 0.0, 0.0, 0.72)
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_backdrop)
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	_column.add_theme_constant_override("separation", 16)
	centre.add_child(_column)
	_column.add_child(UiTheme.heading("You Have Died", 84, BLOOD))
	_column.add_child(UiTheme.divider(520))
	_killer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_column.add_child(_killer)
	var gap := Control.new()
	gap.custom_minimum_size.y = 24
	_column.add_child(gap)
	_menu.add_item("Rise at Checkpoint", respawn)
	_column.add_child(_menu)
	_prompts = PromptBar.in_corner(self)
	_prompts.show_prompts([["a", "Rise"]])
	modulate.a = 0.0
	hide()
	Events.hero_died.connect(_on_hero_died)

func _exit_tree() -> void:
	if Events.hero_died.is_connected(_on_hero_died):
		Events.hero_died.disconnect(_on_hero_died)
	if visible:
		Music.duck(false)

func _process(delta: float) -> void:
	if _wait < 0.0:
		return
	_wait -= delta
	if _wait < 0.0:
		open()

func _on_hero_died(hero: Hero, event: DamageEvent) -> void:
	if hero != slot.hero:
		return
	Sound.play("hero_death")
	Music.duck(true)
	_killer.text = "Slain by %s" % killer_name(event)
	_wait = delay
	if delay <= 0.0:
		_wait = -1.0
		open()

func open() -> void:
	is_open = true
	show()
	_menu.reset()
	_menu.take_focus()
	_fade(1.0)

# Brings the hero back at the checkpoint, at full health, and gets out of the way
func respawn() -> void:
	var hero := slot.hero
	if not is_open or not is_instance_valid(hero):
		return
	is_open = false
	hero.revive()
	hero.global_position = respawn_point()
	hero.velocity = Vector3.ZERO
	var camera := get_viewport().get_camera_3d()
	if camera and camera.has_method("snap"):
		camera.snap()
	Sound.play("respawn")
	Music.duck(false)
	Events.hero_respawned.emit(hero)
	_fade(0.0).tween_callback(hide)

func respawn_point() -> Vector3:
	return Session.checkpoint if Session.checkpoint.is_finite() else zone.hero_start

# "a Skeleton Warrior", or an elite by its name
static func killer_name(event: DamageEvent) -> String:
	if event == null or not is_instance_valid(event.source):
		return "the dark"
	var monster := event.source as Monster
	if monster == null:
		return "the dark"
	if monster.elite:
		var plate: NamePlate = monster.find_child("NamePlate", false, false)
		if plate:
			return plate.title.text
	var noun := monster.def.display_name
	return ("an " if noun.substr(0, 1).to_lower() in ["a", "e", "i", "o", "u"] else "a ") + noun

func _fade(to: float) -> Tween:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", to, FADE / SceneManager.speed_scale)
	return _tween
