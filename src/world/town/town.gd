class_name Town
extends Zone
# Emberfall, the hub: a walled square under the moon with a waypoint in the middle, the stash chest in
# one corner and the merchant's stall in the other. The gate north leads out to the graveyard. No
# monsters, so A always talks rather than swings.

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
	add_child(_merchant_model(Vector3(11, 0, -11)))
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

# Hilde: the hooded rogue with her knives put away, idling behind the stall
func _merchant_model(at: Vector3) -> Node3D:
	var rig: Node3D = load("res://assets/kaykit/adventurers/characters/Rogue_Hooded.glb").instantiate()
	rig.position = at
	for slot in HeroModel.HAND_SLOTS:
		var bone := rig.find_child(slot, true, false)
		if bone:
			for prop in bone.get_children():
				prop.free()
	var animations: AnimationPlayer = rig.find_child("AnimationPlayer", true, false)
	animations.get_animation("Idle").loop_mode = Animation.LOOP_LINEAR
	animations.autoplay = "Idle"
	return rig
