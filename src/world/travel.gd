class_name Travel
extends RefCounted
# Going from one zone to another: every hero's bags, gear, level and wounds are put by in Session, the
# game scene is rebuilt around the new zone, and each hero picks up where they left off. arrival names
# where in the new zone they come in ("waypoint", "gate", "stairs"), which each zone reads.

const GAME := "res://src/game/game.tscn"

static func go(zone_id: String, arrival := "") -> bool:
	if SceneManager.is_changing:
		return false
	prepare(zone_id, arrival)
	return SceneManager.go_to(GAME)

# Everything about going except the scene change
static func prepare(zone_id: String, arrival := "") -> void:
	for slot in Session.slots:
		if is_instance_valid(slot.hero):
			Session.carried[slot.index] = snapshot(slot.hero)
	Session.zone_id = zone_id
	Session.arrival = arrival
	Session.checkpoint = Vector3.INF

static func snapshot(hero: Hero) -> Dictionary:
	return {
		"class": hero.hero_class.id, "level": hero.level, "xp": hero.xp, "health": hero.health,
		"power": hero.power, "inventory": hero.inventory.to_dict(), "equipment": hero.equipment.to_dict(),
	}

# Puts back what the hero's slot carried in. Called once the hero is in the tree.
static func restore(hero: Hero) -> void:
	var data: Dictionary = Session.carried.get(hero.slot.index, {})
	if data.is_empty() or data.get("class") != hero.hero_class.id:
		return
	hero.level = int(data.level)
	hero.xp = int(data.xp)
	hero.inventory.load_dict(data.inventory)
	hero.equipment.load_dict(data.equipment)
	hero.health = hero.max_health() if data.health <= 0.0 else minf(data.health, hero.max_health())
	hero.power = minf(data.power, hero.max_power())
	hero.health_changed.emit(hero.health, hero.max_health())
	hero.power_changed.emit(hero.power, hero.max_power())
