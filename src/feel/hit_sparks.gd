class_name HitSparks
extends Node
# The spray off a blow that lands: a few bright chips flung from where it hit, away from whoever
# struck. Hits come thick and fast in a pack fight, so a small pool of particle systems is reused
# round-robin rather than one made per hit.

const POOL := 6
const AMOUNT := 10
const CHEST := 1.0
const COLOUR := Color(1.0, 0.86, 0.6)

var pool: Array[GPUParticles3D] = []
var _next := 0

func _ready() -> void:
	for i in POOL:
		var spray := SkillVfx.burst(self, Vector3.ZERO, COLOUR, AMOUNT, 7.0, 0.28, 0.35)
		spray.emitting = false
		# A cone flung along the spray's +Z, which spark() turns to point away from the striker
		var process: ParticleProcessMaterial = spray.process_material
		process.direction = Vector3(0, 0.35, 1)
		process.spread = 55.0
		process.flatness = 0.0
		# The pool keeps them; SkillVfx's one-shot would free them when done
		spray.finished.disconnect(spray.queue_free)
		pool.append(spray)

# Sparks off a body standing at `at`, flung away from `from`
func spark(at: Vector3, from: Vector3) -> void:
	var spray := pool[_next]
	_next = (_next + 1) % pool.size()
	var away := at - from
	away.y = 0.0
	spray.global_position = at + Vector3(0, CHEST, 0) - away.normalized() * 0.3
	if away.length_squared() > 0.0001:
		spray.global_basis = Basis.looking_at(-away.normalized(), Vector3.UP)
	spray.restart()

func clear() -> void:
	for spray in pool:
		spray.emitting = false
