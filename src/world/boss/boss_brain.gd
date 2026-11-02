class_name BossBrain
extends Node
# Vargoth's mind, separate from the ordinary MonsterBrain (which it switches off): it sleeps on its
# throne until a hero comes close, roars, then fights in phases. Below 60% health it roars again,
# quickens and starts raising the dead; below 30% it quickens again. Each roar is a breather for the
# hero. The slam, its big hit, lands a little ahead of it and is painted on the floor first.
# step() does a frame's thinking, so the tests can drive a fight without waiting.

signal phase_changed(phase: int)

enum State { DORMANT, ROARING, FIGHTING, DEAD }

# Skill bar slots, as the def lists them
const CLEAVE := 0
const SLAM := 1
const SUMMON := 2
# Health fraction at which each phase starts
const PHASES := [1.0, 0.6, 0.3]
# Attack and move speed bonus in each phase
const HASTE := [0.0, 0.25, 0.5]
const ROAR_SECONDS := 1.8
const ROAR_ANIMATION := "Taunt"
# How far it'll follow a hero out of its room before giving up and standing guard
const LEASH := 30.0
const MAX_SUMMONS := 6

var monster: Monster
var state := State.DORMANT
var phase := 0
var target: Hero
var summons: Array[Monster] = []
# What plays again once it's dead: the zone's own music
var return_music := "crypt"
var _roar_left := 0.0
var _moving := false

func _init(owner_monster: Monster) -> void:
	name = "BossBrain"
	monster = owner_monster

func _ready() -> void:
	var ordinary := monster.brain
	ordinary.process_mode = Node.PROCESS_MODE_DISABLED
	for connection in [[monster.hurt, ordinary._on_hurt], [monster.died, ordinary._on_died], [monster.skill_bar.used, ordinary._on_skill_used]]:
		if connection[0].is_connected(connection[1]):
			connection[0].disconnect(connection[1])
	monster.add_to_group(&"bosses")
	monster.hurt.connect(_on_hurt)
	monster.died.connect(_on_died)
	monster.skill_bar.used.connect(_on_skill_used)

static func phase_for(health_fraction: float) -> int:
	var found := 0
	for i in range(1, PHASES.size()):
		if health_fraction <= PHASES[i]:
			found = i
	return found

# What to do: slam if it's ready and the hero's within its range, raise the dead once wounded, swing
# when close, otherwise close the distance. ready is [cleave, slam, summon].
static func choose(current_phase: int, distance: float, ready: Array, cleave_reach: float, slam_reach: float) -> StringName:
	if current_phase >= 1 and ready[SUMMON]:
		return &"summon"
	if ready[SLAM] and distance <= slam_reach:
		return &"slam"
	if distance <= cleave_reach:
		return &"cleave" if ready[CLEAVE] else &"wait"
	return &"chase"

func _physics_process(delta: float) -> void:
	step(delta)

func step(delta: float) -> void:
	match state:
		State.DEAD:
			return
		State.DORMANT:
			var seen := _nearest_hero(monster.def.aggro_range)
			if seen:
				target = seen
				engage()
		State.ROARING:
			_roar_left -= delta
			_halt()
			if _roar_left <= 0.0:
				state = State.FIGHTING
		State.FIGHTING:
			if not is_instance_valid(target) or not target.alive or _distance(target) > LEASH:
				target = _nearest_hero(LEASH)
			if target == null:
				_halt()
			else:
				_fight()
	monster.move_and_slide()

func engage() -> void:
	Events.boss_engaged.emit(monster)
	Music.play("boss")
	roar()

func roar() -> void:
	state = State.ROARING
	_roar_left = ROAR_SECONDS
	_halt()
	monster.animations.speed_scale = 1.0
	monster.play(ROAR_ANIMATION, 0.1)
	Sound.play("boss_roar")
	Feedback.shake(0.6)

func enter_phase(next: int) -> void:
	phase = next
	monster.stats.clear_source(&"boss_phase")
	monster.stats.add_modifier(&"boss_phase", Stats.ATTACK_SPEED, 0.0, HASTE[next])
	monster.stats.add_modifier(&"boss_phase", Stats.MOVE_SPEED, 0.0, HASTE[next])
	# Raising the dead is ready the moment it's allowed
	monster.skill_bar.set_skill(SUMMON, monster.skill_bar.skills[SUMMON])
	phase_changed.emit(next)
	Events.boss_phase_changed.emit(monster, next)
	roar()

func living_summons() -> int:
	summons = summons.filter(func(raised: Monster) -> bool: return is_instance_valid(raised) and raised.alive)
	return summons.size()

func _fight() -> void:
	var bar := monster.skill_bar
	if bar.busy:
		_halt()
		return
	var distance := _distance(target)
	var ready := [bar.can_use(CLEAVE), bar.can_use(SLAM), bar.can_use(SUMMON) and living_summons() < MAX_SUMMONS]
	var cleave_reach: float = bar.skills[CLEAVE].reach
	var slam_reach: float = bar.skills[SLAM].reach
	match choose(phase, distance, ready, cleave_reach, slam_reach):
		&"summon":
			_halt()
			bar.use_on(SUMMON, target)
		&"slam":
			_halt()
			bar.use_on(SLAM, target)
		&"cleave":
			_halt()
			bar.use_on(CLEAVE, target)
		&"wait":
			_halt()
			monster.face(target.global_position - monster.global_position)
		&"chase":
			var towards := target.global_position - monster.global_position
			towards.y = 0.0
			monster.velocity = towards.normalized() * monster.stats.value(Stats.MOVE_SPEED)
			monster.face(towards)
			if not _moving:
				_moving = true
				monster.animations.speed_scale = 1.0
				monster.play(monster.def.walk_animation, 0.2)

func _halt() -> void:
	monster.velocity = Vector3.ZERO
	if _moving:
		_moving = false
		if not monster.skill_bar.busy:
			monster.play(monster.def.idle_animation, 0.2)

func _on_hurt(event: DamageEvent) -> void:
	if not monster.alive:
		return
	if state == State.DORMANT:
		if event.source is Hero:
			target = event.source
		engage()
	var next := phase_for(monster.health / monster.max_health())
	if next > phase:
		enter_phase(next)

func _on_died(_event: DamageEvent) -> void:
	state = State.DEAD
	monster.velocity = Vector3.ZERO
	Sound.play("boss_slain")
	Feedback.shake(1.0)
	Music.play(return_music)

# Its big attacks are painted on the floor for exactly as long as the wind-up takes
func _on_skill_used(index: int, skill: SkillDef) -> void:
	var wind_up := skill.hit_time / maxf(monster.stats.value(Stats.ATTACK_SPEED), 0.1)
	var warning: Telegraph
	match index:
		SLAM:
			warning = Telegraph.ring(BossSlam.landing(monster, monster.facing(), skill), skill.radius, wind_up)
		CLEAVE:
			warning = Telegraph.cone(monster.global_position, monster.rotation.y, skill.reach + MonsterStrike.SLACK, skill.cone_degrees, wind_up)
		_:
			return
	monster.get_parent().add_child(warning)
	Sound.play("telegraph", 0.8)

func _nearest_hero(within: float) -> Hero:
	var best: Hero
	var best_distance := within
	for node in get_tree().get_nodes_in_group(&"heroes"):
		var hero := node as Hero
		if hero and hero.alive and _distance(hero) <= best_distance:
			best = hero
			best_distance = _distance(hero)
	return best

func _distance(other: Node3D) -> float:
	var offset := other.global_position - monster.global_position
	offset.y = 0.0
	return offset.length()
