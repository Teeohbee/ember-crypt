class_name LeapFlight
extends Node
# One leap in the air: carries the caster along an arc from one spot to another over the skill's
# flight time, then lands with a crash that hits everything within its radius, shakes the camera and
# kicks up dust. Steps in physics frames, so a test can drive it by hand.

var caster: Combatant
var skill: SkillDef
var from: Vector3
var to: Vector3
var seconds := 0.5
var height := 2.2
var _time := 0.0

func _init(leaper: Combatant, leap: SkillDef, start: Vector3, end: Vector3) -> void:
	name = "LeapFlight"
	caster = leaper
	skill = leap
	from = start
	to = end
	seconds = float(leap.params.get("flight", 0.5))
	height = float(leap.params.get("height", 2.2))

func _physics_process(delta: float) -> void:
	if not is_instance_valid(caster) or not caster.alive:
		queue_free()
		return
	_time = minf(_time + delta, seconds)
	var t := _time / seconds
	var at := from.lerp(to, t)
	at.y = from.y + height * 4.0 * t * (1.0 - t)
	caster.global_position = at
	if _time >= seconds:
		_land()

func _land() -> void:
	caster.global_position = to
	set_physics_process(false)
	for victim in Targeting.in_radius(to, caster.hostiles(), skill.radius):
		Combat.hit(caster, victim, skill)
	var world := caster.get_parent()
	Sound.play("leap_land", randf_range(0.95, 1.05))
	SkillVfx.ring(world, to, 0.5, skill.radius, SkillVfx.DUST, 0.5, 0.3)
	SkillVfx.ring(world, to, 0.3, skill.radius * 0.6, SkillVfx.FURY, 0.35)
	SkillVfx.burst(world, to, SkillVfx.DUST, 20, 6.0, 0.6, 0.5)
	SkillVfx.flash(world, to, SkillVfx.FURY, 2.0, 7.0, 0.3)
	Feedback.shake(0.6)
	Feedback.hit_stop(0.05)
	queue_free()
