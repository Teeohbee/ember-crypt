class_name SkillBar
extends Node
# A combatant's skills, one per button, and the timing of using them: check cooldown and power, pick a
# target with aim assist, turn to it, play the animation, then fire the effect at hit_time. The caster
# can't start another skill until recovery has passed (busy). Heroes and monsters both use it.

signal used(index: int, skill: SkillDef)
# At hit_time, when the effect goes off
signal fired(index: int, skill: SkillDef, target: Combatant)

const SLOTS := 6
# Full width of the aim-assist cone
const ASSIST_CONE := 110.0

var caster: Combatant
var skills: Array[SkillDef] = []
var last_target: Combatant
# The caster's level, which gates skills by unlock_level; 0 (monsters) means nothing is gated
var level := 0
var _cooldowns := PackedFloat32Array()
var _cooldown_lengths := PackedFloat32Array()
var _busy_for := 0.0
var busy: bool:
	get: return _busy_for > 0.0

func _init(owner_caster: Combatant) -> void:
	name = "SkillBar"
	caster = owner_caster
	skills.resize(SLOTS)
	_cooldowns.resize(SLOTS)
	_cooldown_lengths.resize(SLOTS)

func set_skill(index: int, skill: SkillDef) -> void:
	skills[index] = skill
	_cooldowns[index] = 0.0

func cooldown_left(index: int) -> float:
	return _cooldowns[index]

# 1 just used, 0 ready
func cooldown_fraction(index: int) -> float:
	return 0.0 if _cooldown_lengths[index] <= 0.0 else _cooldowns[index] / _cooldown_lengths[index]

# False for an empty slot or a skill the caster's level hasn't reached
func is_unlocked(index: int) -> bool:
	var skill := skills[index]
	return skill != null and (level <= 0 or skill.unlock_level <= level)

func can_use(index: int) -> bool:
	var skill := skills[index]
	return is_unlocked(index) and caster.alive and not busy and _cooldowns[index] <= 0.0 and caster.power + 0.001 >= skill.cost

# Uses the skill in slot index, aimed roughly along aim. False if it couldn't be used.
func use(index: int, aim: Vector3) -> bool:
	if not can_use(index):
		return false
	var skill := skills[index]
	var target := Targeting.best_target(caster.global_position, aim, caster.hostiles(), skill.reach, ASSIST_CONE, last_target)
	return _start(index, skill, target, aim)

# Uses a skill on a chosen target, skipping aim assist (monster brains know who they're hitting)
func use_on(index: int, target: Combatant) -> bool:
	if not can_use(index):
		return false
	return _start(index, skills[index], target, caster.facing())

func _start(index: int, skill: SkillDef, target: Combatant, aim: Vector3) -> bool:
	caster.spend_power(skill.cost)
	if target:
		last_target = target
		aim = target.global_position - caster.global_position
	aim.y = 0
	if aim.length_squared() < 0.0001:
		aim = caster.facing()
	aim = aim.normalized()
	caster.face(aim)
	var speed := maxf(caster.stats.value(Stats.ATTACK_SPEED), 0.1)
	_lunge(skill, target, skill.hit_time / speed)
	var cooldown := skill.cooldown * (1.0 - clampf(caster.stats.value(Stats.COOLDOWN_REDUCTION), 0.0, 0.8))
	_cooldowns[index] = cooldown
	_cooldown_lengths[index] = cooldown
	_busy_for = skill.recovery / speed
	if caster.has_method("play_skill_animation"):
		caster.play_skill_animation(skill, speed)
	used.emit(index, skill)
	Events.skill_used.emit(caster, skill)
	_fire_later(index, skill, target, aim, skill.hit_time / speed)
	return true

# Melee skills step-lunge into reach: with params "strike_range" set, a target further off than that is
# closed on during the wind-up, so the blow lands at hit_time
func _lunge(skill: SkillDef, target: Combatant, wind_up: float) -> void:
	var strike_range: float = skill.params.get("strike_range", 0.0)
	if strike_range <= 0.0 or target == null:
		return
	var gap := target.global_position - caster.global_position
	gap.y = 0.0
	var distance := gap.length()
	if distance > strike_range + 0.05:
		Shove.apply(caster, gap / distance * (distance - strike_range), maxf(wind_up, 0.08))

func _fire_later(index: int, skill: SkillDef, target: Combatant, aim: Vector3, delay: float) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay, false).timeout
	if not is_instance_valid(caster) or not caster.alive:
		return
	if not is_instance_valid(target) or not target.alive:
		target = null
	skill.instantiate_effect().execute(caster, skill, target, aim)
	fired.emit(index, skill, target)

func _process(delta: float) -> void:
	_busy_for = maxf(_busy_for - delta, 0.0)
	for i in SLOTS:
		if _cooldowns[i] > 0.0:
			_cooldowns[i] = maxf(_cooldowns[i] - delta, 0.0)
