class_name HeroPickup
extends RefCounted
# Picking things up, D3 console style. Gold is scooped up by walking over it. An item in reach gets
# highlighted, and A picks it up instead of attacking - unless something hostile is close, when A
# always means fight. After a pickup A stays taken until it's let go, so holding it doesn't swing.

signal highlight_changed(drop: FloorDrop)
signal bag_full(item: Item)

const REACH := 2.2
const GOLD_REACH := 1.6
const HOSTILE_CLEAR := 4.0
const PRIMARY := &"skill_1"

var hero: Hero
var highlighted: FloorDrop
var _primary_taken := false

func _init(owner_hero: Hero) -> void:
	hero = owner_hero

# Called each physics step before skills; true means A belongs to pickup right now
func physics_step() -> bool:
	_scoop_gold()
	var near := nearest_item()
	if near and hostile_close():
		near = null
	if near != highlighted:
		if is_instance_valid(highlighted):
			highlighted.set_highlighted(false)
		highlighted = near
		if near:
			near.set_highlighted(true)
		highlight_changed.emit(near)
	if _primary_taken:
		if hero.slot.pressed(PRIMARY):
			return true
		_primary_taken = false
	if near and hero.slot.just_pressed(PRIMARY):
		pick_up(near)
		_primary_taken = true
		return true
	return false

func nearest_item() -> FloorDrop:
	var best: FloorDrop = null
	var best_distance := REACH
	for drop in FloorDrop.live:
		if drop.is_gold() or not drop.landed or not drop.belongs_to(hero.slot):
			continue
		var distance := _flat_distance(drop)
		if distance <= best_distance:
			best_distance = distance
			best = drop
	return best

func hostile_close() -> bool:
	for hostile in hero.hostiles():
		if _flat_distance(hostile) < HOSTILE_CLEAR:
			return true
	return false

# Into the bag, or a refusal if it's full (the item stays on the floor)
func pick_up(drop: FloorDrop) -> bool:
	if not hero.inventory.add(drop.item):
		Sound.play("denied")
		bag_full.emit(drop.item)
		return false
	Sound.play("pickup")
	Events.item_picked_up.emit(drop.item, hero)
	drop.collect()
	if highlighted == drop:
		highlighted = null
		highlight_changed.emit(null)
	return true

func _scoop_gold() -> void:
	for i in range(FloorDrop.live.size() - 1, -1, -1):
		var drop := FloorDrop.live[i]
		if drop.is_gold() and drop.landed and drop.belongs_to(hero.slot) and _flat_distance(drop) <= GOLD_REACH:
			hero.inventory.add_gold(drop.gold)
			Sound.play("pickup_gold", randf_range(0.95, 1.05))
			Feedback.number(drop.global_position + Vector3.UP, "+%d Gold" % drop.gold, FloorDrop.GOLD_COLOUR)
			Events.gold_picked_up.emit(drop.gold, hero)
			drop.collect()

func _flat_distance(node: Node3D) -> float:
	var offset := node.global_position - hero.global_position
	offset.y = 0.0
	return offset.length()
