class_name HalloweenKit
extends RefCounted
# Placing KayKit Halloween Bits pieces by name, the way CryptKit places the dungeon's. These are .gltf
# files that already share one external texture, so they need none of the dungeon's material tricks.
# Fences are 4 m long and centred, like dungeon walls.

const DIR := "res://assets/kaykit/halloween/"

static var _scenes := {}

static func scene(piece: String) -> PackedScene:
	if not _scenes.has(piece):
		_scenes[piece] = load(DIR + piece + ".gltf")
	return _scenes[piece]

# One piece at `at`, turned `yaw` degrees about the vertical
static func place(parent: Node3D, piece: String, at: Vector3, yaw := 0.0, size := 1.0) -> Node3D:
	var node: Node3D = scene(piece).instantiate()
	node.position = at
	node.rotation_degrees.y = yaw
	node.scale = Vector3.ONE * size
	parent.add_child(node)
	return node

# A piece with a box of collision `footprint` metres across (x, z before turning), for things you'd
# walk into. Quarter turns only for the collision.
static func solid(parent: Node3D, piece: String, at: Vector3, footprint: Vector2, yaw := 0.0, size := 1.0) -> Node3D:
	var node := place(parent, piece, at, yaw, size)
	if int(roundf(yaw / 90.0)) % 2 != 0:
		footprint = Vector2(footprint.y, footprint.x)
	CryptKit.blocker(parent, at + Vector3(0, 1.0, 0), Vector3(footprint.x * size, 2.0, footprint.y * size))
	return node
