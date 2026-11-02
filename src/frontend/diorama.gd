class_name Diorama
extends Node3D
# The crypt behind the title, menu and class select: a vaulted chamber with an archway into darkness,
# torches either side, and the two heroes standing in shafts of cold light. Dormant skeletons lie
# about the floor, a promise of what's through the arch. Built from the KayKit dungeon pieces.

const HERO_SPOTS := [Vector3(-2.6, 0, -1.5), Vector3(2.6, 0, -1.5)]
const SPOT_DIM := 2.5
const SPOT_LIT := 9.0

var heroes: Array[HeroModel] = []
var spots: Array[SpotLight3D] = []

func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Look.environment()
	add_child(env)
	_build_room()
	for i in Session.CLASSES.size():
		var hero := HeroModel.new(Session.CLASSES[i])
		hero.position = HERO_SPOTS[i]
		# Turned a touch toward the middle, as if sizing each other up
		hero.rotation_degrees.y = 14.0 if i == 0 else -14.0
		add_child(hero)
		heroes.append(hero)
		var spot := Look.spotlight(Look.MOONLIGHT, SPOT_DIM, 20.0)
		spot.position = HERO_SPOTS[i] + Vector3(0, 9, 1.5)
		add_child(spot)
		spot.look_at(HERO_SPOTS[i] + Vector3(0, 1, 0))
		spots.append(spot)
		_candles_around(HERO_SPOTS[i])

# Lights the chosen hero and lowers the other, or with -1 lights both evenly.
func spotlight(index: int, seconds := 0.6) -> void:
	for i in spots.size():
		var energy := SPOT_DIM * 1.6 if index == -1 else (SPOT_LIT if i == index else SPOT_DIM * 0.6)
		var tween := create_tween()
		tween.tween_property(spots[i], "light_energy", energy, seconds).set_trans(Tween.TRANS_SINE)

# The floor is cells x -2..2, z -3..1 (20 m wide); the far wall's inner face is at z = -13.5 and the
# side walls' at x = +-9.5.
func _build_room() -> void:
	CryptKit.floor(self, Vector2i(-2, -3), Vector2i(2, 1), 7)
	# The far wall, with the arch in the middle, and side walls running toward the camera
	CryptKit.wall(self, Vector2i(-2, -3), Vector2i(3, -3), func(i: int) -> String:
		return "wall_arched" if i == 2 else ("wall_cracked" if i == 0 else "wall"))
	CryptKit.wall(self, Vector2i(-2, -3), Vector2i(-2, 2))
	CryptKit.wall(self, Vector2i(3, -3), Vector2i(3, 2))
	# Through the arch: a short passage with the treasure at the end, falling away into black
	CryptKit.floor(self, Vector2i(0, -5), Vector2i(0, -4), 3)
	for z in [-16.0, -20.0]:
		CryptKit.place(self, "wall", Vector3(-2, 0, z), 90)
		CryptKit.place(self, "wall", Vector3(2, 0, z), 90)
	CryptKit.place(self, "chest_gold", Vector3(0, 0, -17.0))
	var deep := Look.torch_light(1.4, 6.0)
	deep.position = Vector3(0, 2.2, -15.5)
	add_child(deep)

	for side in [-1.0, 1.0]:
		CryptKit.place(self, "torch_mounted", Vector3(side * 6.5, 2.4, -13.5))
		add_child(Look.flame(Vector3(side * 6.5, 2.95, -13.1)))
		var torch := Look.torch_light()
		torch.position = Vector3(side * 6.5, 3.0, -12.4)
		add_child(torch)
		CryptKit.place(self, "banner_patternA_red", Vector3(side * 3.1, 0.2, -13.5))
		CryptKit.place(self, "candle_triple", Vector3(side * 1.7, 0, -12.9))
		var glow := _candle_light()
		glow.position = Vector3(side * 1.7, 0.9, -12.6)
		add_child(glow)
		CryptKit.place(self, "pillar_decorated", Vector3(side * 8.4, 0, -12.4))
		CryptKit.place(self, "pillar", Vector3(side * 8.4, 0, -2.0))
	CryptKit.place(self, "rubble_large", Vector3(-8.2, 0, -6.5), 90)
	CryptKit.place(self, "barrel_large", Vector3(8.4, 0, -9.0), 20)
	CryptKit.place(self, "barrel_small_stack", Vector3(8.6, 0, -6.8), -30)
	CryptKit.place(self, "sword_shield_broken", Vector3(-7.0, 0, 2.0), 80)

	var sleepers := [
		["Skeleton_Minion", Vector3(-5.8, 0, -5.2), 40.0],
		["Skeleton_Warrior", Vector3(6.0, 0, -4.4), -60.0],
		["Skeleton_Minion", Vector3(5.0, 0, 3.0), 200.0],
	]
	for sleeper: Array in sleepers:
		var bones: Node3D = load("res://assets/kaykit/skeletons/characters/%s.glb" % sleeper[0]).instantiate()
		bones.position = sleeper[1]
		bones.rotation_degrees.y = sleeper[2]
		add_child(bones)
		var animations: AnimationPlayer = bones.find_child("AnimationPlayer", true, false)
		animations.play("Skeletons_Inactive_Floor_Pose")

func _candles_around(at: Vector3) -> void:
	for corner in [Vector3(-1.3, 0, 0.9), Vector3(1.3, 0, 0.9)]:
		CryptKit.place(self, "candle_thin_lit", at + corner, randf() * 360.0)
	var glow := _candle_light()
	glow.position = at + Vector3(0, 0.8, 1.0)
	add_child(glow)

func _candle_light() -> OmniLight3D:
	var light := Look.torch_light(0.9, 4.0)
	light.light_color = Look.CANDLE
	light.shadow_enabled = false
	return light
