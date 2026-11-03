class_name CryptKit
extends RefCounted
# Placing KayKit dungeon pieces by name. The kit is on a 4 m grid: large floor tiles are 4 m square
# and centred on their cell, walls are 4 m long, 4 m tall and 1 m thick, centred on a cell edge.
# Some files are .gltf.glb and some plain .glb, so pieces are looked up by bare name.

const DIR := "res://assets/kaykit/dungeon/"
const CELL := 4.0

static var _scenes := {}

static func scene(piece: String) -> PackedScene:
	if not _scenes.has(piece):
		var path := DIR + piece + ".gltf.glb"
		if not ResourceLoader.exists(path):
			path = DIR + piece + ".glb"
		_scenes[piece] = load(path)
	return _scenes[piece]

# One piece at `at`, turned `yaw` degrees about the vertical.
static func place(parent: Node3D, piece: String, at: Vector3, yaw := 0.0) -> Node3D:
	var node: Node3D = scene(piece).instantiate()
	# The doorway piece comes with its door shut, which heroes and skeletons would walk straight
	# through; our doorways all stand open
	var door := node.find_child("wall_doorway_door")
	if door:
		door.free()
	node.position = at
	node.rotation_degrees.y = yaw
	parent.add_child(node)
	return node

# A rectangle of large floor tiles covering cells [from, to] inclusive, with the odd rubble-strewn
# tile so it doesn't look like lino. (The dirt tiles sit lower and read as holes from above, so
# they're for caves, not crypts.) Seeded, so a room looks the same every time.
static func floor(parent: Node3D, from: Vector2i, to: Vector2i, seed_value := 1) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for x in range(from.x, to.x + 1):
		for z in range(from.y, to.y + 1):
			var roll := rng.randf()
			var piece := "floor_tile_large"
			if roll > 0.82:
				piece = "floor_tile_large_rocks"
			place(parent, piece, Vector3(x, 0, z) * CELL, rng.randi_range(0, 3) * 90.0)

# A run of wall along cell edges. `from` and `to` are grid corners on one line; walls face +z or +x
# into the room on the side the room is.
static func wall(parent: Node3D, from: Vector2i, to: Vector2i, piece_for: Callable = Callable()) -> void:
	var step := Vector2i(signi(to.x - from.x), signi(to.y - from.y))
	var count := maxi(absi(to.x - from.x), absi(to.y - from.y))
	var yaw := 0.0 if step.y == 0 else 90.0
	for i in count:
		var corner := from + step * i
		var middle := (Vector2(corner) + Vector2(step) * 0.5 - Vector2(0.5, 0.5)) * CELL
		var piece: String = piece_for.call(i) if piece_for.is_valid() else "wall"
		# Walls dissolve when they stand between the camera and a hero (WallFade)
		place(parent, piece, Vector3(middle.x, 0, middle.y), yaw).add_to_group(WallFade.GROUP)

# A box of collision for walking into, sized in metres.
static func blocker(parent: Node3D, centre: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = centre
	parent.add_child(body)
	return body
