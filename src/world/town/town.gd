class_name Town
extends Zone
# Emberfall, the hub: a walled square under the moon, dressed for harvest, with a waypoint in the
# middle, the stash chest in one corner and the merchant's stall in the other. A cobbled road runs from
# the waypoint to the gate north, which two knights keep, out to the graveyard. Lantern posts, autumn
# pines, a pumpkin stall, benches and a tavern table with a mage nursing a drink make it a place people
# live. No monsters, so A always talks rather than swings (the pumpkins on the floor do smash).

const MERCHANT := "Hilde the Pedlar"
const STOCK := 8
const ARRIVALS := {"": Vector3(0, 0, 6), "waypoint": Vector3(0, 0, 4.5), "gate": Vector3(0, 0, -8)}

var vendor := Vendor.new()
var stash: Interactable
var merchant: Interactable

func _init() -> void:
	id = "town"
	display_name = "Emberfall"
	music = "town"
	name = "Town"

func environment() -> Environment:
	return Look.night_environment(0.02)

func build() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	add_child(Look.moon(0.5))
	RoomBuilder.floor_tiles(self, Vector2i(-4, -3), Vector2i(4, 3), 0.12, rng)
	RoomBuilder.wall_run(self, Vector2i(-4, -3), Vector2i(5, -3), 4, false, rng)
	RoomBuilder.wall_run(self, Vector2i(-4, -3), Vector2i(-4, 4), -1, false, rng)
	RoomBuilder.wall_run(self, Vector2i(5, -3), Vector2i(5, 4), -1, false, rng)
	RoomBuilder.wall_run(self, Vector2i(-4, 4), Vector2i(5, 4), -1, true, rng)
	_gate()
	_square()
	_stash_corner()
	_stall()
	_road(rng)
	_harvest(rng)
	_folk()
	var waypoint := Waypoint.new(id)
	waypoint.position = Vector3(0, 0, 2)
	add_child(waypoint)
	hero_start = ARRIVALS.get(Session.arrival, ARRIVALS[""])

# The gate is the middle of the north wall: an open doorway, banners either side
# The gate is the doorway in the middle of the north wall, banners either side; the road beyond is
# walled off, since the gate is used rather than walked through
func _gate() -> void:
	CryptKit.blocker(self, Vector3(0, 2, -15.5), Vector3(4, 4, 1))
	for x in [-4.0, 4.0]:
		CryptKit.place(self, "banner_patternA_red", Vector3(x, 0, -14))
	for x in [-2.6, 2.6]:
		CryptKit.place(self, "torch_mounted", Vector3(x, 2.4, -13.5))
		add_child(Look.flame(Vector3(x, 2.95, -13.1)))
	var light := Look.torch_light(3.4, 11.0)
	light.position = Vector3(0, 3.2, -12.0)
	add_child(light)
	var exit := ZoneExit.new("Out to the graveyard", "graveyard", "gate")
	exit.position = Vector3(0, 0, -12.5)
	add_child(exit)

func _square() -> void:
	for x in [-5.0, 5.0]:
		RoomBuilder.brazier(self, Vector3(x, 0, 2))
	for at in [Vector3(-14, 0, -11), Vector3(-14, 0, 9), Vector3(14, 0, 9)]:
		RoomBuilder.prop_at(self, "barrel_large", at)
	RoomBuilder.prop_at(self, "crates_stacked", Vector3(-12, 0, 11), 90.0)
	RoomBuilder.prop_at(self, "keg", Vector3(14, 0, -2))
	CryptKit.place(self, "barrel_small_stack", Vector3(12.4, 0, 11))
	for x in [-10.0, 10.0]:
		CryptKit.place(self, "banner_thin_red", Vector3(x, 0, -14))
	for side in [-1.0, 1.0]:
		CryptKit.place(self, "torch_mounted", Vector3(side * 17.5, 2.4, 0), -side * 90.0)
		add_child(Look.flame(Vector3(side * 17.1, 2.95, 0)))
		var light := Look.torch_light(2.8, 10.0)
		light.shadow_enabled = false
		light.position = Vector3(side * 16.2, 3.0, 0)
		add_child(light)

func _stash_corner() -> void:
	RoomBuilder.prop_at(self, "chest_gold", Vector3(-12, 0, -11))
	for at in [Vector3(-14, 0, -8.5), Vector3(-10, 0, -12.6)]:
		CryptKit.place(self, "candle_triple", at)
	var candle := OmniLight3D.new()
	candle.light_color = Look.CANDLE
	candle.light_energy = 1.6
	candle.omni_range = 5.0
	candle.position = Vector3(-12, 1.6, -9.5)
	candle.set_script(Flicker)
	add_child(candle)
	stash = Interactable.new("Stash", 2.8)
	stash.name = "Stash"
	stash.position = Vector3(-12, 0, -9.6)
	add_child(stash)
	stash.used.connect(func(hero: Hero) -> void:
		Sound.play("stash")
		WorldScreen.show_screen(StashScreen.new(Session.stash), hero))

func _stall() -> void:
	RoomBuilder.prop_at(self, "table_long_tablecloth", Vector3(11, 0, -9), 90.0)
	CryptKit.place(self, "coin_stack_small", Vector3(10, 1, -9))
	CryptKit.place(self, "bottle_A_labeled_brown", Vector3(11.2, 1, -8.8))
	CryptKit.place(self, "bottle_B_green", Vector3(11.7, 1, -9.1))
	CryptKit.place(self, "sword_shield", Vector3(13.6, 0, -11.5))
	add_child(_npc("Rogue_Hooded", Vector3(11, 0, -11), 0.0, [], "Idle"))
	var lamp := OmniLight3D.new()
	lamp.light_color = Look.CANDLE
	lamp.light_energy = 2.0
	lamp.omni_range = 6.0
	lamp.position = Vector3(11, 2.4, -8.5)
	lamp.set_script(Flicker)
	add_child(lamp)
	merchant = Interactable.new("Trade", 3.0)
	merchant.name = "Merchant"
	merchant.position = Vector3(11, 0, -7)
	add_child(merchant)
	merchant.used.connect(func(hero: Hero) -> void:
		if vendor.stock.is_empty():
			var rng := RandomNumberGenerator.new()
			rng.randomize()
			vendor.stock = Vendor.roll_stock(Vendor.all_bases(), hero.level, rng, STOCK)
		WorldScreen.show_screen(VendorScreen.new(vendor, MERCHANT), hero))

# Cobbles from the waypoint up to the gate
func _road(rng: RandomNumberGenerator) -> void:
	var z := 0.4
	while z > -13.0:
		for x in [-0.95, 0.95]:
			var stone: String = ["path_A", "path_B", "path_C", "path_D"][rng.randi_range(0, 3)]
			HalloweenKit.place(self, stone, Vector3(x + rng.randf_range(-0.1, 0.1), 0.02, z), rng.randi_range(0, 3) * 90.0)
		z -= 1.9

# Lantern posts round the square, autumn pines along the north wall, a pumpkin stall by Hilde's,
# jack-o'-lanterns at the gate, benches by the waypoint and a tavern table in the south-west corner
func _harvest(rng: RandomNumberGenerator) -> void:
	for at in [Vector3(-8.5, 0, -5), Vector3(8.5, 0, -5), Vector3(-8.5, 0, 9), Vector3(8.5, 0, 9)]:
		var side := signf(at.x)
		HalloweenKit.place(self, "post_lantern", at, 90.0 * side)
		CryptKit.blocker(self, at + Vector3(0, 1.0, 0), Vector3(0.5, 2.0, 0.5))
		var light := OmniLight3D.new()
		light.light_color = Look.CANDLE
		light.light_energy = 1.6
		light.omni_range = 7.0
		light.omni_attenuation = 1.8
		light.position = at + Vector3(-side * 1.1, 2.5, 0)
		light.set_script(Flicker)
		add_child(light)
	for tree in [["tree_pine_orange_medium", Vector3(-16, 0, -5)], ["tree_pine_yellow_medium", Vector3(16, 0, 3.5)],
			["tree_pine_yellow_small", Vector3(6.5, 0, -12.6)], ["tree_pine_orange_small", Vector3(-7, 0, -12.6)]]:
		HalloweenKit.solid(self, tree[0], tree[1], Vector2(1.2, 1.2), rng.randf_range(0, 360))
	RoomBuilder.prop_at(self, "table_medium", Vector3(5.5, 0, -9.5))
	for at in [Vector3(5.0, 1.0, -9.8), Vector3(6.0, 1.0, -9.2)]:
		HalloweenKit.place(self, ["pumpkin_orange_small", "pumpkin_yellow_small"][rng.randi_range(0, 1)], at, rng.randf_range(0, 360))
	for at in [Vector3(4.0, 0, -8.0), Vector3(7.2, 0, -7.6), Vector3(3.4, 0, -10.8), Vector3(-15.5, 0, 0.5), Vector3(15.5, 0, -8.5)]:
		var pumpkin := Breakable.make(["pumpkin_orange", "pumpkin_yellow", "pumpkin_orange_small"][rng.randi_range(0, 2)], rng.randi_range(0, 3) * 90.0)
		pumpkin.position = at
		add_child(pumpkin)
	for at in [Vector3(-5.5, 0, -12.6), Vector3(5.5, 0, -12.6) + Vector3(-1.4, 0, 0.8), Vector3(-9.6, 0, -12.2), Vector3(13.6, 0, -6.2)]:
		HalloweenKit.solid(self, ["pumpkin_orange_jackolantern", "pumpkin_yellow_jackolantern"][rng.randi_range(0, 1)], at, Vector2(1.2, 1.2), 180.0)
		var glow := OmniLight3D.new()
		glow.light_color = Graveyard.PUMPKIN
		glow.light_energy = 1.1
		glow.omni_range = 3.5
		glow.position = at + Vector3(0, 0.7, 0.6)
		glow.set_script(Flicker)
		add_child(glow)
	for x in [-4.0, 4.0]:
		HalloweenKit.solid(self, "bench", Vector3(x, 0, 6.5), Vector2(2.0, 0.8))
	RoomBuilder.prop_at(self, "table_medium", Vector3(-10, 0, 6))
	CryptKit.place(self, "plate_food_A", Vector3(-10.3, 1.0, 6.1))
	CryptKit.place(self, "bottle_A_brown", Vector3(-9.6, 1.0, 5.8))
	for at in [Vector3(-11.6, 0, 6), Vector3(-10, 0, 7.6)]:
		CryptKit.place(self, "stool", at)

# Two knights keeping the gate, and a mage taking her ease at the tavern table
func _folk() -> void:
	for side in [-1.0, 1.0]:
		var guard := _npc("Knight", Vector3(side * 2.8, 0, -11.6), 0.0, ["1H_Sword", "Round_Shield"], "Idle")
		guard.name = "Guard%s" % ("West" if side < 0 else "East")
		add_child(guard)
		CryptKit.blocker(self, Vector3(side * 2.8, 1.0, -11.6), Vector3(0.9, 2.0, 0.9))
	CryptKit.place(self, "chair", Vector3(-8.4, 0, 6), -90.0)
	add_child(_npc("Mage", Vector3(-8.4, 0, 6), -90.0, [], "Sit_Chair_Idle"))

# A townsperson: one of the adventurer rigs holding only `held`, looping `idle`
func _npc(rig_name: String, at: Vector3, yaw: float, held: Array, idle: String) -> Node3D:
	var rig: Node3D = load("res://assets/kaykit/adventurers/characters/%s.glb" % rig_name).instantiate()
	rig.position = at
	rig.rotation_degrees.y = yaw
	for slot in HeroModel.HAND_SLOTS:
		var bone := rig.find_child(slot, true, false)
		if bone:
			for prop in bone.get_children():
				if not prop.name in held:
					prop.free()
	var animations: AnimationPlayer = rig.find_child("AnimationPlayer", true, false)
	animations.get_animation(idle).loop_mode = Animation.LOOP_LINEAR
	animations.autoplay = idle
	return rig
