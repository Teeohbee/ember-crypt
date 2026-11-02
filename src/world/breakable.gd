class_name Breakable
extends Combatant
# Barrels, crates and pumpkins that burst at a blow, D3 style. A one-health Combatant, so every skill
# that hits skeletons hits these too (they're among a hero's hostiles, never a monster's), but they
# aren't monsters: no XP, no monster group, and aim assist would rather pick a skeleton (Targeting).
# Breaking one throws splinters with a smash and now and then spills a little gold.

const GROUP := &"breakables"
const WOOD := Color(0.62, 0.42, 0.24)
const PUMPKIN := Color(1.0, 0.55, 0.15)
# piece: [kit ("dungeon" or "halloween"), footprint (x, z), height, debris colour, sound]
const KINDS := {
	"barrel_small": ["dungeon", Vector2(1.0, 1.0), 1.2, WOOD, "smash"],
	"barrel_large": ["dungeon", Vector2(1.6, 1.6), 1.8, WOOD, "smash"],
	"barrel_small_stack": ["dungeon", Vector2(1.8, 1.8), 1.6, WOOD, "smash"],
	"keg": ["dungeon", Vector2(1.6, 1.8), 1.4, WOOD, "smash"],
	"box_small": ["dungeon", Vector2(1.0, 1.0), 1.0, WOOD, "smash"],
	"box_large": ["dungeon", Vector2(1.6, 1.6), 1.6, WOOD, "smash"],
	"crates_stacked": ["dungeon", Vector2(2.0, 2.0), 2.0, WOOD, "smash"],
	"pumpkin_orange": ["halloween", Vector2(1.0, 1.0), 0.7, PUMPKIN, "squelch"],
	"pumpkin_orange_small": ["halloween", Vector2(0.6, 0.6), 0.55, PUMPKIN, "squelch"],
	"pumpkin_yellow": ["halloween", Vector2(1.0, 1.0), 0.7, PUMPKIN, "squelch"],
	"pumpkin_yellow_small": ["halloween", Vector2(0.6, 0.6), 0.55, PUMPKIN, "squelch"],
}
const GOLD := Vector2i(2, 7)

var piece := ""
var model: Node3D
var gold_chance := 0.3

static func is_breakable(piece_name: String) -> bool:
	return KINDS.has(piece_name)

static func make(piece_name: String, yaw := 0.0) -> Breakable:
	var breakable := Breakable.new()
	breakable.piece = piece_name
	var kind: Array = KINDS[piece_name]
	var scene: PackedScene = CryptKit.scene(piece_name) if kind[0] == "dungeon" else HalloweenKit.scene(piece_name)
	breakable.model = scene.instantiate()
	breakable.model.rotation_degrees.y = yaw
	breakable.add_child(breakable.model)
	var footprint: Vector2 = kind[1]
	if int(roundf(yaw / 90.0)) % 2 != 0:
		footprint = Vector2(footprint.y, footprint.x)
	var shape := CollisionShape3D.new()
	shape.name = "Shape"
	var box := BoxShape3D.new()
	box.size = Vector3(footprint.x, kind[2], footprint.y)
	shape.shape = box
	shape.position.y = kind[2] * 0.5
	breakable.add_child(shape)
	return breakable

func _init() -> void:
	name = "Breakable"
	team = Team.MONSTERS
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	stats.set_base(Stats.MAX_HEALTH, 1.0)
	stats.set_base(Stats.ARMOUR, 0.0)
	rng.randomize()

# Not super(): a breakable joins its own group rather than the monsters'
func _ready() -> void:
	add_to_group(GROUP)
	add_to_group(&"combatants")
	health = max_health()

func _on_died(event: DamageEvent) -> void:
	var kind: Array = KINDS[piece]
	var parent := get_parent()
	var centre := global_position + Vector3(0, kind[2] * 0.4, 0)
	$Shape.set_deferred(&"disabled", true)
	model.visible = false
	# Sparks glow, so splinters go in darker than they should look
	SkillVfx.burst(parent, centre, kind[3].darkened(0.6), 18, 6.0, 0.7, 0.55)
	SkillVfx.burst(parent, centre, kind[3].darkened(0.8), 10, 3.5, 0.9, 0.8)
	Sound.play(kind[4], randf_range(0.9, 1.1))
	if rng.randf() < gold_chance:
		var slot: PlayerSlot = event.source.slot if event and event.source is Hero else null
		var spot := global_position + Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized() * 1.2
		FloorDrop.toss_gold(parent, rng.randi_range(GOLD.x, GOLD.y), centre, spot, slot)
	remove_from_group(GROUP)
	remove_from_group(&"combatants")
