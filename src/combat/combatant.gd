class_name Combatant
extends CharacterBody3D
# Anything that fights: heroes and monsters. Holds the stat sheet and health, takes hits, dies once.
# Subclasses react through hurt / died (or by overriding _on_hurt / _on_died) rather than replacing
# take_hit, so every hit gets the same bookkeeping.

signal hurt(event: DamageEvent)
signal died(event: DamageEvent)
signal health_changed(health: float, max_health: float)
signal power_changed(power: float, max_power: float)

enum Team { HEROES, MONSTERS }

const TEAM_GROUPS := {Team.HEROES: &"heroes", Team.MONSTERS: &"monsters"}

var team := Team.MONSTERS
var stats := Stats.new()
var health := 0.0
# Fury / Arcane Power for heroes; monsters have it but rarely use it
var power := 0.0
var rng := RandomNumberGenerator.new()
var alive: bool:
	get: return health > 0.0

func _ready() -> void:
	add_to_group(TEAM_GROUPS[team])
	add_to_group(&"combatants")
	health = max_health()

func _process(delta: float) -> void:
	if not alive:
		return
	var regen := stats.value(Stats.HEALTH_REGEN)
	if regen != 0.0 and health < max_health():
		heal(regen * delta)
	var power_regen := stats.value(Stats.POWER_REGEN)
	if power_regen != 0.0:
		var before := power
		power = clampf(power + power_regen * delta, 0.0, max_power())
		if power != before:
			power_changed.emit(power, max_power())

func max_health() -> float:
	return stats.value(Stats.MAX_HEALTH)

func take_hit(event: DamageEvent) -> void:
	if not alive:
		return
	health = maxf(health - event.amount, 0.0)
	event.killed = health <= 0.0
	health_changed.emit(health, max_health())
	_on_hurt(event)
	hurt.emit(event)
	Events.damage_dealt.emit(event)
	if event.killed:
		_on_died(event)
		died.emit(event)

func heal(amount: float) -> void:
	if not alive:
		return
	health = minf(health + amount, max_health())
	health_changed.emit(health, max_health())

# Brings a dead combatant back at full health (a hero at a checkpoint)
func revive() -> void:
	health = max_health()
	health_changed.emit(health, max_health())

# Living combatants on the other side
func hostiles() -> Array[Combatant]:
	var other: StringName = TEAM_GROUPS[Team.MONSTERS if team == Team.HEROES else Team.HEROES]
	var found: Array[Combatant] = []
	for node in get_tree().get_nodes_in_group(other):
		if node is Combatant and node.alive:
			found.append(node)
	return found

# Spends power if there's enough; false (and nothing spent) if not
func spend_power(amount: float) -> bool:
	if amount > power + 0.001:
		return false
	power -= amount
	power_changed.emit(power, max_power())
	return true

func gain_power(amount: float) -> void:
	power = clampf(power + amount, 0.0, max_power())
	power_changed.emit(power, max_power())

func max_power() -> float:
	return stats.value(Stats.MAX_POWER)

# KayKit rigs face +Z, so combatants do too: the body turns, the model rides along
func facing() -> Vector3:
	return global_basis.z

func face(direction: Vector3) -> void:
	direction.y = 0
	if direction.length_squared() > 0.0001:
		rotation.y = atan2(direction.x, direction.z)

func _on_hurt(_event: DamageEvent) -> void:
	pass

func _on_died(_event: DamageEvent) -> void:
	pass
