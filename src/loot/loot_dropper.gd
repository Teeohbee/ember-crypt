class_name LootDropper
extends Node
# Listens for kills and drops what the dead leave behind, rolled for whoever landed the killing blow
# (their class, magic find and gold find). Elites drop more and better; bosses more and better still.

const SCATTER_MIN := 0.8
const SCATTER_MAX := 1.7

var roller := LootRoller.new()
# For monsters whose def names no table
var default_table := LootTable.new()

func _init() -> void:
	name = "LootDropper"
	default_table.drop_chance = 0.35
	default_table.max_drops = 1
	default_table.gold_chance = 0.5
	default_table.gold_min = 3
	default_table.gold_max = 9
	default_table.rarity_weights = {0: 60, 1: 30, 2: 9, 3: 1}

func _ready() -> void:
	roller.rng.randomize()
	Events.monster_killed.connect(_on_monster_killed)

func _exit_tree() -> void:
	Events.monster_killed.disconnect(_on_monster_killed)

func _on_monster_killed(monster: Monster, event: DamageEvent) -> void:
	var slot: PlayerSlot = event.source.slot if event and event.source is Hero else Session.slots[0]
	drop_for(monster, slot)

# What an elite or a boss adds to its roll: guaranteed extra items, a rarity floor, and magic and
# gold find on top of the hero's
static func boost(is_boss: bool, elite: bool) -> Dictionary:
	if is_boss:
		return {"rolls": 4, "min_rarity": Item.Rarity.RARE, "magic_find": 1.0, "gold_find": 1.0}
	if elite:
		return {"rolls": 2, "min_rarity": Item.Rarity.MAGIC, "magic_find": 0.5, "gold_find": 0.5}
	return {"rolls": 0, "min_rarity": Item.Rarity.NORMAL, "magic_find": 0.0, "gold_find": 0.0}

func drop_for(monster: Monster, slot: PlayerSlot) -> void:
	var hero := slot.hero if slot and is_instance_valid(slot.hero) else null
	var table := monster.def.loot_table if monster.def.loot_table else default_table
	var extra := boost(monster.def.is_boss, monster.elite)
	var drops := roller.roll_drops(table, monster.def.level,
		(hero.stats.value(Stats.MAGIC_FIND) if hero else 0.0) + extra.magic_find,
		(hero.stats.value(Stats.GOLD_FIND) if hero else 0.0) + extra.gold_find,
		hero.hero_class.id if hero else "", extra.rolls, extra.min_rarity)
	var parent := monster.get_parent()
	var from := monster.global_position + Vector3.UP * 0.8
	var count: int = drops.items.size() + (1 if drops.gold > 0 else 0)
	var turn := roller.rng.randf() * TAU
	var spots: Array[Vector3] = []
	for i in count:
		var angle := turn + TAU * i / maxf(count, 1)
		spots.append(monster.global_position + Vector3(cos(angle), 0, sin(angle)) * roller.rng.randf_range(SCATTER_MIN, SCATTER_MAX))
	for i in drops.items.size():
		FloorDrop.toss_item(parent, drops.items[i], from, spots[i], slot)
		Events.item_dropped.emit(drops.items[i], spots[i], slot)
	if drops.gold > 0:
		FloorDrop.toss_gold(parent, drops.gold, from, spots[-1], slot)
