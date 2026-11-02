class_name Checkpoint
extends Area3D
# Touch it and it's where you come back when you die.

const RADIUS := 2.0

var reached := false

func _init() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = RADIUS
	shape.shape = sphere
	add_child(shape)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is Hero and body.alive:
		Session.checkpoint = global_position
		if not reached:
			reached = true
			Events.checkpoint_reached.emit(self, body)
