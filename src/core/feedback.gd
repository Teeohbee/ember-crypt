extends Node
# Hit feel lives here: every hit Combat lands comes through hit(), so hit-stop, shake, damage numbers,
# flashes, knockback, rumble and impact sounds are tuned in one place. Skills can lean on it through
# their params: "hit_stop" (seconds) and "shake" (0-1) set how heavy their blows feel, "cast_sound" and
# "impact_sound" name their sounds. Monster deaths come through Events and burst into bones.

const STOP_SCALE := 0.05
const MAX_STOP := 0.2
const TRAUMA_DECAY := 1.6
const BURST_POOL := 6
const NUMBER_HEIGHT := 2.3
# A killing blow throws the body this much further than a blow it survives
const KILL_THROW := 2.6

const COLOURS := {
	DamageEvent.Kind.PHYSICAL: Color("f2e8d5"),
	DamageEvent.Kind.FIRE: Color("ff8a3a"),
	DamageEvent.Kind.COLD: Color("8fd3ff"),
	DamageEvent.Kind.LIGHTNING: Color("fff27a"),
	DamageEvent.Kind.ARCANE: Color("c79bff"),
	DamageEvent.Kind.POISON: Color("9be06a"),
}
const CRIT := Color("ffc93c")
const HURT := Color("ff4a3a")
const EVADED := Color("b8b0a0")

# 0-1, how hard the camera is shaking; GameCamera reads shake_amount()
var trauma := 0.0
var numbers := DamageNumbers.new()
var flashes := HitFlash.new()
var bursts: Array[BoneBurst] = []
var sparks := HitSparks.new()
var stopped: bool:
	get: return _stop_left > 0.0

var _stop_left := 0.0
var _scale_before := 1.0
var _next_burst := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(numbers)
	add_child(flashes)
	add_child(sparks)
	for i in BURST_POOL:
		var burst := BoneBurst.new()
		bursts.append(burst)
		add_child(burst)
	Events.monster_killed.connect(_on_monster_killed)
	Events.skill_used.connect(_on_skill_used)
	get_tree().scene_changed.connect(reset)

func hit(event: DamageEvent) -> void:
	if event == null or not is_instance_valid(event.target) or not event.target.is_inside_tree():
		return
	var target := event.target
	var params: Dictionary = event.skill.params if event.skill else {}
	# Smashing a barrel is a crunch and a jolt, not a fight: no number, no knockback
	if target is Breakable:
		if is_instance_valid(event.source):
			sparks.spark(target.global_position, event.source.global_position)
		hit_stop(0.03)
		shake(0.1)
		return
	var on_hero := target.team == Combatant.Team.HEROES
	var colour: Color = HURT if on_hero else (CRIT if event.crit else COLOURS.get(event.kind, Color.WHITE))
	number(target.global_position + Vector3(0, NUMBER_HEIGHT, 0), str(maxi(roundi(event.amount), 1)), colour, event.crit)
	flashes.flash(target, HitFlash.RED if on_hero else HitFlash.WHITE)
	if event.knockback > 0.0 and is_instance_valid(event.source):
		knockback(target, target.global_position - event.source.global_position, event.knockback * (KILL_THROW if event.killed else 1.0))
	if on_hero:
		shake(0.35)
		Sound.play("hurt", randf_range(0.9, 1.05))
		_rumble(target, 0.4, 0.6, 0.18)
		return
	if is_instance_valid(event.source):
		sparks.spark(target.global_position, event.source.global_position)
	var stop: float = params.get("hit_stop", 0.025)
	var heft: float = params.get("shake", 0.12)
	if event.crit:
		stop += 0.03
		heft *= 1.5
	if event.killed:
		stop += 0.03
		heft += 0.1
	hit_stop(stop)
	shake(heft)
	var impact: String = params.get("impact_sound", "impact")
	Sound.play("impact_crit" if event.crit and impact == "impact" else impact, randf_range(0.92, 1.08))
	if event.source is Combatant:
		_rumble(event.source, 0.25, 0.1 + heft * 0.5, 0.08)

# Freezes the action for a moment, so a heavy blow lands. Overlapping stops don't add up: the longer wins.
func hit_stop(seconds: float) -> void:
	seconds = minf(seconds, MAX_STOP)
	if seconds <= 0.0:
		return
	if not stopped:
		_scale_before = Engine.time_scale
		Engine.time_scale = _scale_before * STOP_SCALE
	_stop_left = maxf(_stop_left, seconds)

# Kicks the camera; strength 0-1
func shake(strength: float) -> void:
	trauma = clampf(trauma + strength, 0.0, 1.0)

# How far the camera should shake right now, 0-1: trauma squared, so small knocks stay small, scaled
# by the player's screen shake setting (7 of 10 is as designed)
func shake_amount() -> float:
	return trauma * trauma * Settings.get_value("screen_shake") / 7.0

# A number (or word) that pops off a point in the world
func number(at: Vector3, text: String, colour := Color.WHITE, big := false) -> void:
	numbers.show_number(at, text, colour, big)

# Shoves a combatant `metres` along `direction`, sliding to a stop against walls
func knockback(target: Combatant, direction: Vector3, metres: float) -> void:
	direction.y = 0.0
	if direction.length_squared() < 0.0001:
		direction = -target.facing()
	Shove.apply(target, direction.normalized() * metres, 0.18 + metres * 0.06)

# A hit that didn't land because the target was rolling clear
func evaded(target: Combatant) -> void:
	number(target.global_position + Vector3(0, NUMBER_HEIGHT, 0), "Evaded", EVADED)

func burst_bones(at: Vector3, away := Vector3.ZERO, strength := 1.0) -> BoneBurst:
	var burst := bursts[_next_burst]
	_next_burst = (_next_burst + 1) % bursts.size()
	burst.burst(at, away, strength)
	return burst

# Drops everything mid-flight: on a scene change nothing should follow the player out
func reset() -> void:
	if stopped:
		_stop_left = 0.0
		Engine.time_scale = _scale_before
	trauma = 0.0
	numbers.clear()
	for burst in bursts:
		burst.visible = false
		burst.set_physics_process(false)
	sparks.clear()

func _process(delta: float) -> void:
	# delta is game time; during a stop the game runs at STOP_SCALE, so this is the time it would have been
	var unstopped := delta / STOP_SCALE if stopped else delta
	if stopped:
		_stop_left -= unstopped
		if _stop_left <= 0.0:
			_stop_left = 0.0
			Engine.time_scale = _scale_before
	trauma = maxf(trauma - TRAUMA_DECAY * unstopped, 0.0)

func _on_monster_killed(monster: Monster, event: DamageEvent) -> void:
	if not is_instance_valid(monster) or not monster.is_inside_tree():
		return
	var away := Vector3.ZERO
	if event and is_instance_valid(event.source):
		away = monster.global_position - event.source.global_position
	burst_bones(monster.global_position, away, monster.def.scale)
	Sound.play("bones", randf_range(0.9, 1.1))
	# The corpse lies a while, then sinks through the floor before it's freed
	var sink := monster.create_tween()
	sink.tween_interval(Monster.CORPSE_SECONDS - 1.2)
	sink.tween_property(monster.model, "position:y", -1.2 * monster.def.scale, 1.1).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

func _on_skill_used(_caster: Combatant, skill: SkillDef) -> void:
	var sound: String = skill.params.get("cast_sound", "")
	if sound != "":
		Sound.play(sound, randf_range(0.94, 1.06))

func _rumble(combatant: Combatant, weak: float, strong: float, seconds: float) -> void:
	if not combatant is Hero or not Settings.get_value("rumble"):
		return
	var device: int = combatant.slot.device
	for pad in (Input.get_connected_joypads() if device < 0 else [device]):
		Input.start_joy_vibration(pad, weak, strong, seconds)
