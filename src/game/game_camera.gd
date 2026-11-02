class_name GameCamera
extends Camera3D
# The ARPG camera: a fixed angle that never rotates, following the middle of every hero (a list of one
# until co-op) with a little lag. It leans a little ahead of where the heroes are running, so there's
# more to see in front than behind; shakes when Feedback says so; and dissolves walls in the way.

# About 50 degrees down and pulled well back, D3 style: a whole room and the pack coming at you on
# screen, at the cost of reading a skeleton's face
const OFFSET := Vector3(0, 15.5, 13.3)
const FOLLOW := 6.0
# Lead: this many seconds of the heroes' velocity, at most MAX_LEAD metres, eased in and out
const LEAD_SECONDS := 0.3
const MAX_LEAD := 2.8
const LEAD_EASE := 2.5
# At full shake: metres the view slides and radians it rolls
const SHAKE_SLIDE := 0.4
const SHAKE_ROLL := 0.025

var wall_fade := WallFade.new(self)
var _lead := Vector3.ZERO
var _shake_time := 0.0
var _rest_rotation := Vector3.ZERO

func _init() -> void:
	name = "GameCamera"
	fov = 44.0

func _ready() -> void:
	add_child(wall_fade)
	snap()

func focus() -> Vector3:
	var heroes := Session.heroes()
	if heroes.is_empty():
		return global_position - OFFSET - _lead
	var middle := Vector3.ZERO
	for hero in heroes:
		middle += hero.global_position
	return middle / heroes.size()

# Where the camera leans for heroes moving at this (average) velocity
static func lead_for(velocity: Vector3) -> Vector3:
	velocity.y = 0.0
	return (velocity * LEAD_SECONDS).limit_length(MAX_LEAD)

func snap() -> void:
	var target := focus()
	_lead = Vector3.ZERO
	global_position = target + OFFSET
	look_at(target + Vector3(0, 1.0, 0))
	_rest_rotation = rotation

func _process(delta: float) -> void:
	var heroes := Session.heroes()
	var velocity := Vector3.ZERO
	for hero in heroes:
		velocity += hero.velocity
	if not heroes.is_empty():
		velocity /= heroes.size()
	_lead = _lead.lerp(lead_for(velocity), 1.0 - exp(-LEAD_EASE * delta))
	global_position = global_position.lerp(focus() + _lead + OFFSET, 1.0 - exp(-FOLLOW * delta))
	_shake(delta)

# Slides and rolls the view by the shake, around where it rests; smooth layered waves rather than noise,
# so it rattles without jittering
func _shake(delta: float) -> void:
	var amount := Feedback.shake_amount()
	_shake_time += delta
	var t := _shake_time
	h_offset = SHAKE_SLIDE * amount * (sin(t * 37.0) * 0.6 + sin(t * 23.0 + 1.3) * 0.4)
	v_offset = SHAKE_SLIDE * amount * (sin(t * 41.0 + 0.7) * 0.6 + sin(t * 19.0 + 2.1) * 0.4)
	rotation = _rest_rotation + Vector3(0, 0, SHAKE_ROLL * amount * sin(t * 29.0 + 0.4))
