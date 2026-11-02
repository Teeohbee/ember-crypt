class_name Stats
extends RefCounted
# A stat sheet: base values plus modifiers, each modifier tagged with where it came from so it can be
# taken off again (an unequipped ring, an expired war cry). value() is (base + flats) * (1 + percents).
# Percent modifiers are fractions: 0.1 is +10%.

signal changed

const MAX_HEALTH := &"max_health"
const HEALTH_REGEN := &"health_regen"        # per second
const MAX_POWER := &"max_power"              # Fury / Arcane Power
const POWER_REGEN := &"power_regen"          # per second; negative decays (Fury)
const DAMAGE := &"damage"                    # weapon damage, what a skill's multiplier scales
const ATTACK_SPEED := &"attack_speed"        # 1.0 is normal; scales skill animations and recovery
const CRIT_CHANCE := &"crit_chance"          # 0-1
const CRIT_DAMAGE := &"crit_damage"          # bonus on a crit: 0.5 is +50%
const ARMOUR := &"armour"                    # physical mitigation, armour / (armour + 100)
const RESIST := &"resist"                    # elemental mitigation, 0-1, capped at 0.75
const MOVE_SPEED := &"move_speed"            # metres per second
const COOLDOWN_REDUCTION := &"cooldown_reduction"  # 0-1
const LIFE_ON_HIT := &"life_on_hit"
const MAGIC_FIND := &"magic_find"            # 0.2 is +20% chance of better rarity
const GOLD_FIND := &"gold_find"

const DEFAULTS := {
	MAX_HEALTH: 100.0, HEALTH_REGEN: 0.0, MAX_POWER: 100.0, POWER_REGEN: 0.0, DAMAGE: 10.0,
	ATTACK_SPEED: 1.0, CRIT_CHANCE: 0.05, CRIT_DAMAGE: 0.5, ARMOUR: 0.0, RESIST: 0.0, MOVE_SPEED: 6.0,
	COOLDOWN_REDUCTION: 0.0, LIFE_ON_HIT: 0.0, MAGIC_FIND: 0.0, GOLD_FIND: 0.0,
}

var _base := {}
# source -> Array of [stat, flat, percent]
var _modifiers := {}

func _init(base := {}) -> void:
	for stat: StringName in base:
		_base[StringName(stat)] = float(base[stat])

func base(stat: StringName) -> float:
	return _base.get(stat, DEFAULTS.get(stat, 0.0))

func set_base(stat: StringName, amount: float) -> void:
	_base[stat] = amount
	changed.emit()

func value(stat: StringName) -> float:
	var flat := base(stat)
	var percent := 0.0
	for source: StringName in _modifiers:
		for modifier: Array in _modifiers[source]:
			if modifier[0] == stat:
				flat += modifier[1]
				percent += modifier[2]
	return flat * (1.0 + percent)

func add_modifier(source: StringName, stat: StringName, flat := 0.0, percent := 0.0) -> void:
	if not _modifiers.has(source):
		_modifiers[source] = []
	_modifiers[source].append([stat, flat, percent])
	changed.emit()

func has_source(source: StringName) -> bool:
	return _modifiers.has(source)

func clear_source(source: StringName) -> void:
	if _modifiers.erase(source):
		changed.emit()
