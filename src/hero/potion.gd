class_name Potion
extends Node
# The health potion on LB, D3 style: one bottomless flask that heals a big share of max health at once,
# then needs a long wait. It refuses (with a dull knock) rather than waste itself at full health.

signal drunk(amount: float)
signal refilled

const HEAL_FRACTION := 0.6
const COOLDOWN := 30.0

var drinker: Combatant
var cooldown_left := 0.0
var _cooldown_length := COOLDOWN

func _init(owner_combatant: Combatant) -> void:
	name = "Potion"
	drinker = owner_combatant

func can_drink() -> bool:
	return drinker.alive and cooldown_left <= 0.0 and drinker.health < drinker.max_health()

# 1 just drunk, 0 ready
func cooldown_fraction() -> float:
	return 0.0 if _cooldown_length <= 0.0 else cooldown_left / _cooldown_length

func drink() -> bool:
	if not can_drink():
		return false
	var amount := minf(drinker.max_health() * HEAL_FRACTION, drinker.max_health() - drinker.health)
	drinker.heal(amount)
	_cooldown_length = COOLDOWN * (1.0 - clampf(drinker.stats.value(Stats.COOLDOWN_REDUCTION), 0.0, 0.8))
	cooldown_left = _cooldown_length
	drunk.emit(amount)
	if drinker.is_inside_tree():
		Sound.play("potion")
		Feedback.number(drinker.global_position + Vector3(0, 2.2, 0), "+%d" % roundi(amount), Color(0.55, 0.95, 0.45))
		var world := drinker.get_parent()
		SkillVfx.ring(world, drinker.global_position, 1.4, 0.3, SkillVfx.LIFE, 0.5)
		SkillVfx.burst(world, drinker.global_position, Color(1.0, 0.3, 0.25), 12, 2.0, 0.7, 1.0)
	return true

func tick(delta: float) -> void:
	if cooldown_left > 0.0:
		cooldown_left = maxf(cooldown_left - delta, 0.0)
		if cooldown_left == 0.0:
			refilled.emit()

func _process(delta: float) -> void:
	tick(delta)
