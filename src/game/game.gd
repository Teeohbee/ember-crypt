extends Node3D
# The game: builds the zone Session asks for, puts each player's hero at its start, wakes its monsters
# and follows the heroes with the ARPG camera. The zone name rises in as you arrive, the way Diablo
# announces an area.

var zone: Zone
var hero: Hero
var camera := GameCamera.new()
var huds: Array[Hud] = []
var loot := LootDropper.new()

func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Look.environment()
	add_child(env)
	zone = ZoneLibrary.make(Session.zone_id)
	add_child(zone)
	for slot in Session.slots:
		var spawned := Hero.new(Session.hero_class, slot)
		spawned.position = zone.hero_start
		add_child(spawned)
		spawned.add_child(Look.hero_light())
		var hud := Hud.new(slot)
		add_child(hud)
		hud.add_child(ActionBar.new(slot))
		huds.append(hud)
		hud.add_child(PickupPopup.new(slot))
	hero = Session.slots[0].hero
	add_child(camera)
	zone.populate()
	var pause := PauseMenu.new()
	pause.name = "PauseMenu"
	add_child(pause)
	# M4: drops from kills, and each player's inventory (after the pause menu, so it hears Start first)
	add_child(loot)
	for slot in Session.slots:
		add_child(InventoryScreen.new(slot))
	Music.play(zone.music)
	Events.zone_entered.emit(zone)
	_announce_zone.call_deferred()

func _announce_zone() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_KEEP_SIZE, 170)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.modulate.a = 0.0
	layer.add_child(column)
	column.add_child(UiTheme.heading(zone.display_name, 64, UiTheme.PARCHMENT))
	column.add_child(UiTheme.divider(480))
	await SceneManager.scene_revealed
	var tween := create_tween()
	tween.tween_property(column, "modulate:a", 1.0, 1.2)
	tween.tween_interval(2.4)
	tween.tween_property(column, "modulate:a", 0.0, 1.5)
	tween.tween_callback(layer.queue_free)
