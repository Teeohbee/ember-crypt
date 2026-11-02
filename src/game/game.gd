extends Node3D
# The game, for now a single test room: the chosen hero standing in the middle of a torchlit crypt,
# seen from the ARPG camera. The zone name rises in as you arrive, the way Diablo announces an area.
# M1 gives the hero legs.

const ZONE_NAME := "The Sunken Crypt"
# The camera's offset from the hero: about 50 degrees down, low enough to see the walls you're
# walking toward, close enough to read a skeleton's face
const CAMERA_OFFSET := Vector3(0, 11.0, 9.5)

var hero: HeroModel
var _camera := Camera3D.new()

func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Look.environment()
	add_child(env)
	_build_room()
	hero = HeroModel.new(Session.hero_class)
	add_child(hero)
	hero.add_child(Look.hero_light())
	_camera.fov = 44.0
	_camera.position = hero.position + CAMERA_OFFSET
	add_child(_camera)
	_camera.look_at(hero.position + Vector3(0, 1.0, 0))
	var pause := PauseMenu.new()
	pause.name = "PauseMenu"
	add_child(pause)
	Music.play("crypt")
	_announce_zone.call_deferred()

func _build_room() -> void:
	CryptKit.floor(self, Vector2i(-3, -3), Vector2i(3, 3), 21)
	CryptKit.wall(self, Vector2i(-3, -3), Vector2i(4, -3), func(i: int) -> String:
		return ["wall", "wall_cracked", "wall", "wall_doorway", "wall", "wall_broken", "wall"][i])
	CryptKit.wall(self, Vector2i(-3, -3), Vector2i(-3, 4))
	CryptKit.wall(self, Vector2i(4, -3), Vector2i(4, 4))
	for corner in [Vector3(-8, 0, -8), Vector3(8, 0, -8), Vector3(-8, 0, 8), Vector3(8, 0, 8)]:
		CryptKit.place(self, "pillar", corner)
	for x in [-9.0, 9.0]:
		CryptKit.place(self, "torch_mounted", Vector3(x, 2.4, -13.5))
		add_child(Look.flame(Vector3(x, 2.95, -13.1)))
		var torch := Look.torch_light(3.6, 11.0)
		torch.position = Vector3(x, 3.0, -12.2)
		add_child(torch)
	for z in [-2.0, 6.0]:
		for side in [-1.0, 1.0]:
			CryptKit.place(self, "torch_mounted", Vector3(side * 13.5, 2.4, z), -side * 90.0)
			add_child(Look.flame(Vector3(side * 13.1, 2.95, z)))
			var torch := Look.torch_light(3.0, 10.0)
			torch.position = Vector3(side * 12.2, 3.0, z)
			add_child(torch)
	CryptKit.place(self, "barrel_large", Vector3(-11.5, 0, -11.5), 30)
	CryptKit.place(self, "crates_stacked", Vector3(11.0, 0, -11.2), -10)
	CryptKit.place(self, "rubble_half", Vector3(11.0, 0, 9.0), 120)
	CryptKit.place(self, "table_long_broken", Vector3(-10.5, 0, 4.0), 90)

func _announce_zone() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_KEEP_SIZE, 170)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.modulate.a = 0.0
	layer.add_child(column)
	column.add_child(UiTheme.heading(ZONE_NAME, 64, UiTheme.PARCHMENT))
	column.add_child(UiTheme.divider(480))
	await SceneManager.scene_revealed
	var tween := create_tween()
	tween.tween_property(column, "modulate:a", 1.0, 1.2)
	tween.tween_interval(2.4)
	tween.tween_property(column, "modulate:a", 0.0, 1.5)
	tween.tween_callback(layer.queue_free)
