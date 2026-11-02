class_name Hazard
extends Node3D
# A patch of floor that hurts heroes: a Molten elite's burning trail, or the blast when it dies. A
# pool burns whoever stands in it every tick for its lifetime; a blast is telegraphed for delay
# seconds and then hits once. Damage comes from source (its stats, its skill), so it scales with the
# monster that left it; if that monster's gone, the floor stops hurting.

const TICK := 0.5

var source: Combatant
var skill: SkillDef
var radius := 1.0
var seconds := 1.0
var delay := 0.0
# Times source's weapon damage; below 0 uses the skill's own multiplier
var multiplier := -1.0
var _elapsed := 0.0
var _next_tick := 0.0
var _burst := false

# A burning pool: hurts every TICK for seconds
static func pool(from: Combatant, with: SkillDef, at: Vector3, size: float, lasting: float) -> Hazard:
	var hazard := Hazard.new(from, with, size)
	hazard.seconds = lasting
	hazard.position = at
	hazard.add_child(Telegraph.ring(Vector3.ZERO, size, lasting, Telegraph.FIRE))
	return hazard

# A blast: warns for wind_up seconds, then hits everything inside once
static func blast(from: Combatant, with: SkillDef, at: Vector3, size: float, wind_up: float) -> Hazard:
	var hazard := Hazard.new(from, with, size)
	hazard.delay = wind_up
	hazard.seconds = wind_up
	hazard._burst = true
	hazard.multiplier = with.damage_multiplier * 5.0
	hazard.position = at
	hazard.add_child(Telegraph.ring(Vector3.ZERO, size, wind_up, Telegraph.FIRE))
	return hazard

func _init(from: Combatant, with: SkillDef, size: float) -> void:
	name = "Hazard"
	source = from
	skill = with
	radius = size

func _physics_process(delta: float) -> void:
	_elapsed += delta
	if _burst:
		if _elapsed >= delay:
			_hit_all()
			Feedback.shake(0.4)
			Sound.play("molten", 0.8)
			queue_free()
		return
	if _elapsed >= _next_tick:
		_next_tick += TICK
		_hit_all()
	if _elapsed >= seconds:
		queue_free()

func _hit_all() -> void:
	if not is_instance_valid(source):
		return
	for victim in Targeting.in_radius(global_position, source.hostiles(), radius):
		Combat.hit(source, victim, skill, multiplier)
