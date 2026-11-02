class_name TestRoom
extends Zone
# The torchlit crypt from M0, with a few skeletons to hit: Minions ahead, a Warband led by an elite in
# one far corner and a Coven in the other.

func _init() -> void:
	id = "test_room"
	display_name = "The Sunken Crypt"
	name = "TestRoom"

func build() -> void:
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
	var pack := SpawnPoint.new()
	pack.count = 3
	pack.position = Vector3(0, 0, -6)
	add_child(pack)
	var warband := SpawnPoint.new()
	warband.pack = load("res://src/monsters/packs/warband.tres")
	warband.elite_chance = 1.0
	warband.elite_affixes = 1
	warband.position = Vector3(10, 0, -11)
	add_child(warband)
	var coven := SpawnPoint.new()
	coven.pack = load("res://src/monsters/packs/coven.tres")
	coven.position = Vector3(-10, 0, -11)
	add_child(coven)
