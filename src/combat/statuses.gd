class_name Statuses
extends Node
# Timed buffs and debuffs on one combatant: War Cry's armour, Frost Nova's chill. Each status is a set
# of stat modifiers under the source "status:<id>", so it comes off as cleanly as it went on. Applying
# one again refreshes its timer instead of stacking. An optional visual (an aura, frost at the feet)
# rides on the combatant for as long as the status lasts. Death clears the lot.

signal changed(id: StringName, active: bool)

const NODE_NAME := "Statuses"

var combatant: Combatant
# id -> seconds left
var _left := {}
# id -> Node3D shown while it lasts
var _visuals := {}

# The combatant's status holder, made on first use
static func of(target: Combatant) -> Statuses:
	var found := target.get_node_or_null(NODE_NAME) as Statuses
	if found == null:
		found = Statuses.new()
		found.name = NODE_NAME
		found.combatant = target
		target.add_child(found)
		target.died.connect(func(_event: DamageEvent) -> void: found.clear_all())
	return found

# modifiers: [[stat, flat, percent], ...]
func apply(id: StringName, seconds: float, modifiers: Array, visual: Node3D = null) -> void:
	var source := _source(id)
	combatant.stats.clear_source(source)
	for modifier: Array in modifiers:
		combatant.stats.add_modifier(source, modifier[0], modifier[1], modifier[2])
	var fresh := not _left.has(id)
	_left[id] = seconds
	if visual:
		if _visuals.has(id) and is_instance_valid(_visuals[id]):
			visual.queue_free()
		else:
			combatant.add_child(visual)
			_visuals[id] = visual
	if fresh:
		changed.emit(id, true)

func has(id: StringName) -> bool:
	return _left.has(id)

func time_left(id: StringName) -> float:
	return _left.get(id, 0.0)

func remove(id: StringName) -> void:
	if not _left.erase(id):
		return
	combatant.stats.clear_source(_source(id))
	if _visuals.has(id):
		if is_instance_valid(_visuals[id]):
			_visuals[id].queue_free()
		_visuals.erase(id)
	changed.emit(id, false)

func clear_all() -> void:
	for id: StringName in _left.keys():
		remove(id)

func tick(delta: float) -> void:
	if _left.is_empty():
		return
	for id: StringName in _left.keys():
		_left[id] -= delta
		if _left[id] <= 0.0:
			remove(id)

func _process(delta: float) -> void:
	tick(delta)

static func _source(id: StringName) -> StringName:
	return StringName("status:" + id)
