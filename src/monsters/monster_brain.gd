class_name MonsterBrain
extends Node
# What a monster thinks: a small state machine over idle, chase, attack, hurt and die. It decides a few
# times a second (think) and steers every physics frame, driving its Monster through velocity and
# skill_bar.use_on. Behaviour comes from the MonsterDef: melee and tanks close in, ranged and casters
# hold off at their reach and back away from anyone nearer than keep_away. Skills are tried in order,
# best first, so a cooldown-gated big hit goes before the bread-and-butter swing.

signal state_changed(from: State, to: State)

enum State { IDLE, CHASE, ATTACK, HURT, DIE }

const THINK_INTERVAL := 0.15
const HURT_SECONDS := 0.35
# Waking one of a pack wakes the rest within this distance of it
const PACK_CALL := 16.0
const HOME_SLACK := 1.0
# Summoned skeletons clawing out of the floor
const RISE_SECONDS := 1.6
const RISE_ANIMATION := "Spawn_Ground_Skeletons"
const BACKING_ANIMATION := "Walking_Backwards"
const BLOCK_ANIMATION := "Block_Hit"
# Kiting is slower than charging, so a hero can catch a crossbowman who's run out of room
const BACKING_SPEED := 0.75

var monster: Monster
var state := State.IDLE
var target: Combatant
var home := Vector3.ZERO
# Monsters spawned together; one waking wakes them all
var pack: Array[Monster] = []
var summons: Array[Monster] = []
# Shielding elites shrug off every hit while this is on
var immune := false

var _think_in := 0.0
var _hurt_for := 0.0
var _flinch_ready_in := 0.0
var _asleep_for := 0.0
var _move := Vector3.ZERO
var _backing := false
var _home_set := false
var _returning := false
var _blocked := false
var _announced := false
# The distance it closes to before stopping: just inside its shortest reach for brawlers, most of its
# longest for shooters
var _preferred := 1.5
var _locomotion := PackedStringArray()

func _init(owner_monster: Monster) -> void:
	name = "Brain"
	monster = owner_monster
	var shortest := INF
	var longest := 0.0
	for skill in monster.def.skills:
		if skill and not skill.params.has("max_alive"):
			shortest = minf(shortest, skill.reach)
			longest = maxf(longest, skill.reach)
	if longest > 0.0:
		_preferred = longest * 0.8 if monster.def.keep_away > 0.0 else shortest * 0.75
	for animation in [monster.def.idle_animation, monster.def.walk_animation, monster.def.run_animation, BACKING_ANIMATION]:
		_locomotion.append(animation)

func _ready() -> void:
	# Spread the thinking out, so a pack doesn't all decide on the same frame
	_think_in = randf() * THINK_INTERVAL
	monster.hurt.connect(_on_hurt)
	monster.died.connect(_on_died)
	monster.skill_bar.used.connect(_on_skill_used)
	var backing := monster.animations.get_animation(BACKING_ANIMATION) if monster.animations.has_animation(BACKING_ANIMATION) else null
	if backing:
		backing.loop_mode = Animation.LOOP_LINEAR

func _physics_process(delta: float) -> void:
	if not _home_set:
		home = monster.global_position
		_home_set = true
	if state == State.DIE:
		return
	_flinch_ready_in -= delta
	if _asleep_for > 0.0:
		_asleep_for -= delta
		return
	if state == State.HURT:
		_hurt_for -= delta
		if _hurt_for <= 0.0:
			_set_state(State.CHASE if _has_target() else State.IDLE)
	_think_in -= delta
	if _think_in <= 0.0:
		_think_in = THINK_INTERVAL
		think()
	_steer()
	monster.velocity = _move
	monster.move_and_slide()
	_animate()

# The decisions: who to fight, whether to swing now, or keep closing in
func think() -> void:
	if state == State.DIE or state == State.HURT or _asleep_for > 0.0:
		return
	if state == State.ATTACK:
		if monster.skill_bar.busy:
			return
		_set_state(State.IDLE)
	_keep_or_drop_target()
	if not _has_target() and not _returning:
		var seen := _nearest_hostile(monster.def.aggro_range)
		if seen:
			alert(seen)
	if not _has_target():
		_set_state(State.IDLE)
		return
	var index := pick_skill()
	if index >= 0 and monster.skill_bar.use_on(index, target):
		_move = Vector3.ZERO
		_set_state(State.ATTACK)
		return
	_set_state(State.CHASE)

# The first skill, best first, that's ready and can reach the target; -1 if none
func pick_skill() -> int:
	if not _has_target():
		return -1
	var distance := _flat(target.global_position - monster.global_position).length()
	var bar := monster.skill_bar
	for i in bar.skills.size():
		var skill := bar.skills[i]
		if skill == null or not bar.can_use(i) or distance > skill.reach:
			continue
		if skill.params.has("max_alive") and living_summons() >= int(skill.params["max_alive"]):
			continue
		return i
	return -1

# Turns on a hero, and calls the rest of the pack in
# quietly: woken by a packmate or raised by a summoner, so the pack's one rattle has already sounded
func alert(to: Combatant, quietly := false) -> void:
	if to == null or not is_instance_valid(to) or not to.alive or state == State.DIE or to == target:
		return
	if to.team == monster.team:
		return
	target = to
	_returning = false
	if monster.elite and not _announced:
		# An elite noticing you gets its own bell
		_announced = true
		Sound.play("elite")
	if state == State.IDLE:
		if not quietly:
			Sound.play("skeleton_wake", randf_range(0.85, 1.1))
		_set_state(State.CHASE)
	for mate in pack:
		if is_instance_valid(mate) and mate != monster and mate.alive \
				and mate.global_position.distance_to(monster.global_position) <= PACK_CALL:
			mate.brain.alert(to, true)

# Called by a summoning: lie still while the rising animation plays
func rise() -> void:
	_asleep_for = RISE_SECONDS
	if monster.animations.has_animation(RISE_ANIMATION):
		monster.play(RISE_ANIMATION, 0.0, true)
		monster.animations.speed_scale = monster.animations.get_animation(RISE_ANIMATION).length / RISE_SECONDS

func living_summons() -> int:
	var living := 0
	for summoned in summons:
		if is_instance_valid(summoned) and summoned.alive:
			living += 1
	return living

# Softens a hit before it lands: a shield caught it, or a Shielding elite is immune
func mitigate(event: DamageEvent) -> void:
	_blocked = false
	if immune:
		event.amount = 0.0
		Feedback.number(monster.global_position + Vector3.UP * 2.0, "Immune", UiTheme.FADED)
		return
	var def := monster.def
	if def.block <= 0.0 or monster.skill_bar.busy or not is_instance_valid(event.source):
		return
	var towards := _flat(event.source.global_position - monster.global_position)
	if towards.length_squared() < 0.0001:
		return
	if rad_to_deg(monster.facing().angle_to(towards)) <= def.block_arc * 0.5:
		event.amount *= 1.0 - clampf(def.block, 0.0, 1.0)
		_blocked = true
		Feedback.number(monster.global_position + Vector3.UP * 2.0, "Blocked", UiTheme.FADED)

func _keep_or_drop_target() -> void:
	if target != null and (not is_instance_valid(target) or not target.alive):
		target = null
	if target != null and _flat(monster.global_position - home).length() > monster.def.leash:
		# Too far from home: give up and walk back, not to be distracted on the way
		target = null
		_returning = true

func _has_target() -> bool:
	return target != null and is_instance_valid(target) and target.alive

func _nearest_hostile(within: float) -> Combatant:
	var nearest: Combatant = null
	var best := within
	for hostile in monster.hostiles():
		var distance := _flat(hostile.global_position - monster.global_position).length()
		if distance <= best:
			best = distance
			nearest = hostile
	return nearest

func _steer() -> void:
	_move = Vector3.ZERO
	_backing = false
	var speed := monster.stats.value(Stats.MOVE_SPEED)
	if state == State.CHASE and _has_target():
		var offset := _flat(target.global_position - monster.global_position)
		var distance := offset.length()
		if distance < 0.01:
			return
		var towards := offset / distance
		monster.face(towards)
		if distance > _preferred:
			_move = towards * speed
		elif monster.def.keep_away > 0.0 and distance < monster.def.keep_away:
			_move = -towards * speed * BACKING_SPEED
			_backing = true
	elif state == State.IDLE:
		var offset := _flat(home - monster.global_position)
		if offset.length() > HOME_SLACK:
			_move = offset.normalized() * speed * 0.5
			monster.face(offset)
		elif _returning:
			_returning = false
			monster.heal(monster.max_health())

# Keeps the legs matching the motion, without cutting off a swing, a flinch or a block
func _animate() -> void:
	if monster.skill_bar.busy or state == State.HURT:
		return
	var animations := monster.animations
	var current := animations.current_animation
	if animations.is_playing() and not _locomotion.has(current) and _move == Vector3.ZERO:
		return
	var wanted := monster.def.idle_animation
	if _backing:
		wanted = BACKING_ANIMATION
	elif _move != Vector3.ZERO:
		wanted = monster.def.walk_animation if state == State.IDLE else monster.def.run_animation
	if current != wanted:
		animations.speed_scale = 1.0
		monster.play(wanted, 0.2)

func _on_hurt(event: DamageEvent) -> void:
	if _blocked and monster.alive:
		monster.play(BLOCK_ANIMATION, 0.05)
	if is_instance_valid(event.source) and event.source != monster:
		alert(event.source)
	if not monster.alive or _blocked or monster.skill_bar.busy or _asleep_for > 0.0 or _flinch_ready_in > 0.0:
		_blocked = false
		return
	_flinch_ready_in = monster.def.flinch_cooldown
	_hurt_for = HURT_SECONDS
	_move = Vector3.ZERO
	_set_state(State.HURT)

func _on_died(_event: DamageEvent) -> void:
	_move = Vector3.ZERO
	_set_state(State.DIE)

# Big attacks paint their footprint on the floor first, for exactly as long as the wind-up takes
func _on_skill_used(_index: int, skill: SkillDef) -> void:
	if not skill.params.get("telegraph", false):
		return
	var wind_up := skill.hit_time / maxf(monster.stats.value(Stats.ATTACK_SPEED), 0.1)
	var reach := (skill.radius if skill.radius > 0.0 else skill.reach) + MonsterStrike.SLACK
	var warning: Telegraph
	if skill.cone_degrees >= 360.0:
		warning = Telegraph.ring(monster.global_position, reach, wind_up)
	else:
		warning = Telegraph.cone(monster.global_position, monster.rotation.y, reach, skill.cone_degrees, wind_up)
	monster.get_parent().add_child(warning)
	Sound.play("telegraph", randf_range(0.95, 1.05))

func _set_state(to: State) -> void:
	if to == state:
		return
	var from := state
	state = to
	state_changed.emit(from, to)

static func _flat(vector: Vector3) -> Vector3:
	return Vector3(vector.x, 0.0, vector.z)
