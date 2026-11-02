class_name HeroMotor
extends RefCounted
# Walks the hero where the left stick points and rolls where the right stick flicks. The camera never
# rotates, so stick up is always screen up (world -Z). The hero gets up to speed quickly but not
# instantly, turns to face the way they're going, walks when the stick is barely pushed and runs when
# it's pushed home. The roll is the evade: a burst of speed that slows as it ends, with the first part
# of it untouchable. While a skill plays out the hero stands their ground, sliding to a stop.

const RUN := "Running_A"
const WALK := "Walking_A"
const ROLL := "Dodge_Forward"

const ACCELERATION := 45.0         # m/s per second: full speed in about an eighth of a second
const DECELERATION := 60.0
const BUSY_DECELERATION := 30.0    # a little slide into an attack
const TURN_SPEED := 18.0           # how quickly the hero swings round to face the stick
const WALK_BELOW := 0.55           # stick pushed less than this walks
const WALK_FRACTION := 0.45        # of move speed
const RUN_ANIM_SPEED := 6.0        # metres per second at which Running_A plays at its own pace
const WALK_ANIM_SPEED := 2.4

const ROLL_DISTANCE := 4.5
const ROLL_SECONDS := 0.4
const ROLL_IFRAMES := 0.3          # untouchable for this much of the roll
const ROLL_COOLDOWN := 0.2         # after a roll ends, before the next can start
const FLICK := 0.6                 # the right stick past this rolls...
const CENTRED := 0.3               # ...once it has come back under this

# OTHER: a skill or the roll owns the animation
enum Gait { STILL, WALK, RUN, OTHER }

var hero: Hero
var gait := Gait.STILL
var rolling: bool:
	get: return _roll_elapsed < ROLL_SECONDS

var _roll_direction := Vector3.FORWARD
var _roll_elapsed := ROLL_SECONDS
var _roll_cooldown := 0.0
var _stick_centred := true

func _init(owner_hero: Hero) -> void:
	hero = owner_hero
	for looping in [RUN, WALK]:
		hero.model.animations.get_animation(looping).loop_mode = Animation.LOOP_LINEAR

func physics_step(delta: float) -> void:
	_roll_cooldown = maxf(_roll_cooldown - delta, 0.0)
	if not rolling:
		var wanted := _roll_wanted()
		if wanted != Vector3.ZERO:
			roll(wanted)
	if rolling:
		_roll_step(delta)
	else:
		_walk_step(delta)

# True if the stick has just been flicked out past FLICK, having been centred since the last flick
static func flicked(was_centred: bool, aim: Vector2) -> bool:
	return was_centred and aim.length() >= FLICK

# Starts an evade roll along direction. False if the hero can't roll right now.
func roll(direction: Vector3) -> bool:
	direction.y = 0.0
	if rolling or _roll_cooldown > 0.0 or hero.skill_bar.busy or not hero.alive or direction.length_squared() < 0.0001:
		return false
	_roll_direction = direction.normalized()
	_roll_elapsed = 0.0
	hero.face(_roll_direction)
	hero.invulnerable = true
	gait = Gait.OTHER
	hero.model.play(ROLL, 0.05)
	hero.model.animations.speed_scale = hero.model.animations.get_animation(ROLL).length / ROLL_SECONDS
	Sound.play("roll", randf_range(0.95, 1.05))
	return true

# The right stick (a flick out from the middle) or the debug key, which rolls the way the hero is moving
func _roll_wanted() -> Vector3:
	var aim := hero.slot.aim_vector()
	var flick := flicked(_stick_centred, aim)
	if aim.length() < CENTRED:
		_stick_centred = true
	elif flick:
		_stick_centred = false
	if flick:
		return Vector3(aim.x, 0, aim.y)
	if hero.slot.just_pressed(&"evade"):
		return hero.aim_direction()
	return Vector3.ZERO

func _roll_step(delta: float) -> void:
	_roll_elapsed = minf(_roll_elapsed + delta, ROLL_SECONDS)
	# Fast out of the blocks and slowing at the end; on average it covers ROLL_DISTANCE
	var through := _roll_elapsed / ROLL_SECONDS
	hero.velocity = _roll_direction * ROLL_DISTANCE / ROLL_SECONDS * (1.5 - through)
	hero.invulnerable = _roll_elapsed < ROLL_IFRAMES
	_slide(delta)
	if not rolling:
		hero.invulnerable = false
		_roll_cooldown = ROLL_COOLDOWN
		hero.velocity = _roll_direction * hero.stats.value(Stats.MOVE_SPEED) * 0.5

func _walk_step(delta: float) -> void:
	move(delta, hero.slot.move_vector())

# One step of walking toward where stick points (length 0-1)
func move(delta: float, stick: Vector2) -> void:
	var busy := hero.skill_bar.busy
	var target := Vector3.ZERO
	if stick.length() > 0.1 and not busy:
		var top_speed := hero.stats.value(Stats.MOVE_SPEED) * (WALK_FRACTION if stick.length() < WALK_BELOW else 1.0)
		target = Vector3(stick.x, 0, stick.y).normalized() * top_speed
		hero.rotation.y = lerp_angle(hero.rotation.y, atan2(target.x, target.z), 1.0 - exp(-TURN_SPEED * delta))
	var rate := ACCELERATION if target.length() > hero.velocity.length() else (BUSY_DECELERATION if busy else DECELERATION)
	hero.velocity = hero.velocity.move_toward(target, rate * delta)
	_slide(delta)
	if busy:
		gait = Gait.OTHER
	else:
		_animate(stick.length() < WALK_BELOW)

func _animate(walking: bool) -> void:
	var speed := Vector2(hero.velocity.x, hero.velocity.z).length()
	var wanted := Gait.STILL
	if speed > 0.4:
		wanted = Gait.WALK if walking else Gait.RUN
	var animations := hero.model.animations
	if wanted != gait:
		var was := gait
		gait = wanted
		match gait:
			Gait.STILL:
				animations.speed_scale = 1.0
				# A swing or a roll finishing its follow-through goes back to idle on its own
				if was != Gait.OTHER:
					hero.model.idle()
			Gait.WALK:
				hero.model.play(WALK, 0.15)
			Gait.RUN:
				hero.model.play(RUN, 0.15)
	# Feet keep pace with the ground, so nobody skates
	if gait == Gait.WALK:
		animations.speed_scale = clampf(speed / WALK_ANIM_SPEED, 0.6, 1.6)
	elif gait == Gait.RUN:
		animations.speed_scale = clampf(speed / RUN_ANIM_SPEED, 0.6, 1.5)

# move_and_slide by hand, over this step's delta rather than the engine's, so a step is a step however
# it's driven: slides along whatever it meets, a few times at most
func _slide(delta: float) -> void:
	var motion := hero.velocity * delta
	var height := hero.global_position.y
	for i in 4:
		var collision := hero.move_and_collide(motion)
		hero.global_position.y = height
		if collision == null:
			return
		var normal := collision.get_normal()
		normal.y = 0.0
		normal = normal.normalized()
		motion = collision.get_remainder().slide(normal)
		hero.velocity = hero.velocity.slide(normal)
