class_name HeroMotor
extends RefCounted
# Walks the hero where the left stick points. The camera never rotates, so stick up is always screen
# up (world -Z). Standing still while a skill plays out.

const RUN := "Running_A"

var hero: Hero
var _running := false

func _init(owner_hero: Hero) -> void:
	hero = owner_hero
	hero.model.animations.get_animation(RUN).loop_mode = Animation.LOOP_LINEAR

func physics_step(_delta: float) -> void:
	var stick := hero.slot.move_vector()
	var moving := stick.length() > 0.1 and not hero.skill_bar.busy
	if moving:
		var direction := Vector3(stick.x, 0, stick.y)
		hero.velocity = direction * hero.stats.value(Stats.MOVE_SPEED)
		hero.face(direction)
	else:
		hero.velocity = Vector3.ZERO
	hero.move_and_slide()
	if moving != _running and not hero.skill_bar.busy:
		_running = moving
		hero.model.animations.speed_scale = 1.0
		if moving:
			hero.model.play(RUN, 0.15)
		else:
			hero.model.idle()
	elif hero.skill_bar.busy:
		_running = false
