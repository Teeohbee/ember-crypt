class_name RoomBuilder
extends RefCounted
# Turns a DungeonLayout room into kit pieces: floor, walls with doorways where the layout opens, a
# short passage to the next room east and south, wall torches, and the chunk's props and fires. Every
# wall gets a box of collision; the kit's meshes have none.
#
# Rooms are 5 x 5 tiles with one tile of passage between them, so room centres sit 6 tiles (24 m)
# apart. The camera looks north, so south walls are low balustrades: a full wall there would hide
# the hero.

const ROOM_TILES := 5
const SPACING := 6
const HALF := 2
const WALL_HEIGHT := 4.0
const DOOR_SLOT := 2
# The arch in a doorway piece is about 2 m wide; collision covers the metre either side
const DOOR_POST := 1.0
# Props you can't walk through, and the footprint of their collision in metres
const SOLID := {
	"pillar": Vector2(1.5, 1.5), "pillar_decorated": Vector2(1.5, 1.5), "column": Vector2(0.7, 0.7),
	"barrel_large": Vector2(1.6, 1.6), "barrel_large_decorated": Vector2(1.6, 1.6), "keg": Vector2(1.6, 1.8),
	"crates_stacked": Vector2(2.0, 2.0), "box_stacked": Vector2(3.2, 3.2), "box_large": Vector2(1.6, 1.6),
	"chest": Vector2(1.6, 1.3), "chest_gold": Vector2(1.6, 1.3), "trunk_large_A": Vector2(1.4, 1.2),
	"table_long": Vector2(2.0, 4.0), "table_long_broken": Vector2(2.0, 4.0), "table_long_tablecloth": Vector2(2.0, 4.0),
	"table_long_decorated_A": Vector2(2.0, 4.0), "table_medium": Vector2(2.0, 2.0), "rubble_large": Vector2(6.0, 2.6),
}

# Room centre in world space
static func centre(cell: Vector2i) -> Vector3:
	return Vector3(cell.x, 0, cell.y) * SPACING * CryptKit.CELL

static func build(parent: Node3D, room: DungeonLayout.Room, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, room.cell])
	var c := room.cell * SPACING
	var rubble := room.chunk.rubble if room.chunk else 0.18
	_floor(parent, c - Vector2i(HALF, HALF), c + Vector2i(HALF, HALF), rubble, rng)
	var low := c + Vector2i(-HALF, -HALF)
	var high := c + Vector2i(HALF + 1, HALF + 1)
	_wall(parent, low, Vector2i(high.x, low.y), room.has_door(DungeonLayout.NORTH), false, rng)
	_wall(parent, Vector2i(low.x, high.y), high, room.has_door(DungeonLayout.SOUTH), true, rng)
	_wall(parent, low, Vector2i(low.x, high.y), room.has_door(DungeonLayout.WEST), false, rng)
	_wall(parent, Vector2i(high.x, low.y), high, room.has_door(DungeonLayout.EAST), false, rng)
	if room.has_door(DungeonLayout.EAST):
		_passage(parent, Vector2i(c.x + HALF + 1, c.y), true, rng)
	if room.has_door(DungeonLayout.SOUTH):
		_passage(parent, Vector2i(c.x, c.y + HALF + 1), false, rng)
	_torches(parent, c)
	if room.chunk:
		_furnish(parent, room.chunk, centre(room.cell))

static func _floor(parent: Node3D, from: Vector2i, to: Vector2i, rubble: float, rng: RandomNumberGenerator) -> void:
	for x in range(from.x, to.x + 1):
		for z in range(from.y, to.y + 1):
			var piece := "floor_tile_large_rocks" if rng.randf() < rubble else "floor_tile_large"
			CryptKit.place(parent, piece, Vector3(x, 0, z) * CryptKit.CELL, rng.randi_range(0, 3) * 90.0)

# A run of wall between grid corners `from` and `to` (one line), with a doorway in the middle slot if
# `door`. Low runs are balustrades with a plain gap for the door.
static func _wall(parent: Node3D, from: Vector2i, to: Vector2i, door: bool, low: bool, rng: RandomNumberGenerator) -> void:
	var step := Vector2i(signi(to.x - from.x), signi(to.y - from.y))
	var count := maxi(absi(to.x - from.x), absi(to.y - from.y))
	var along_x := step.y == 0
	for i in count:
		var corner := from + step * i
		var middle2 := (Vector2(corner) + Vector2(step) * 0.5 - Vector2(0.5, 0.5)) * CryptKit.CELL
		var middle := Vector3(middle2.x, 0, middle2.y)
		var is_door := door and i == DOOR_SLOT
		if low:
			if not is_door:
				CryptKit.place(parent, "barrier", middle, 0.0 if along_x else 90.0)
				_block(parent, middle, CryptKit.CELL, along_x)
			continue
		var piece := "wall_doorway" if is_door else _wall_piece(rng)
		CryptKit.place(parent, piece, middle, 0.0 if along_x else 90.0)
		if is_door:
			var offset := (CryptKit.CELL - DOOR_POST) * 0.5
			var axis := Vector3.RIGHT if along_x else Vector3.BACK
			_block(parent, middle - axis * offset, DOOR_POST, along_x)
			_block(parent, middle + axis * offset, DOOR_POST, along_x)
		else:
			_block(parent, middle, CryptKit.CELL, along_x)

static func _wall_piece(rng: RandomNumberGenerator) -> String:
	var roll := rng.randf()
	if roll < 0.12:
		return "wall_cracked"
	if roll < 0.2:
		return "wall_broken"
	if roll < 0.26:
		return "wall_arched"
	return "wall"

static func _block(parent: Node3D, middle: Vector3, length: float, along_x: bool) -> void:
	var size := Vector3(length, WALL_HEIGHT, 1.0) if along_x else Vector3(1.0, WALL_HEIGHT, length)
	CryptKit.blocker(parent, middle + Vector3(0, WALL_HEIGHT * 0.5, 0), size)

# The one-tile passage at `cell` joining a room to the next one east (east_west) or south.
static func _passage(parent: Node3D, cell: Vector2i, east_west: bool, rng: RandomNumberGenerator) -> void:
	_floor(parent, cell, cell, 0.3, rng)
	if east_west:
		_wall(parent, cell, cell + Vector2i(1, 0), false, false, rng)
		_wall(parent, cell + Vector2i(0, 1), cell + Vector2i(1, 1), false, true, rng)
	else:
		_wall(parent, cell, cell + Vector2i(0, 1), false, false, rng)
		_wall(parent, cell + Vector2i(1, 0), cell + Vector2i(1, 1), false, false, rng)

# Two torches on the north wall, either side of where a doorway would be. Only one casts shadows,
# to keep the Deck's shadow atlas light.
static func _torches(parent: Node3D, c: Vector2i) -> void:
	var wall_z := (c.y - HALF - 0.5) * CryptKit.CELL
	for side in [-1, 1]:
		var x: float = (c.x + side) * CryptKit.CELL
		CryptKit.place(parent, "torch_mounted", Vector3(x, 2.4, wall_z + 0.5))
		parent.add_child(Look.flame(Vector3(x, 2.95, wall_z + 0.9)))
		var light := Look.torch_light(3.2, 10.0)
		light.shadow_enabled = side < 0
		light.position = Vector3(x, 3.0, wall_z + 1.8)
		parent.add_child(light)

static func _furnish(parent: Node3D, chunk: RoomChunk, at: Vector3) -> void:
	for prop: Array in chunk.props:
		prop_at(parent, prop[0], at + prop[1], prop[2] if prop.size() > 2 else 0.0)
	for fire in chunk.fires:
		brazier(parent, at + fire)

# One prop, with collision if it's something you'd walk into. Quarter turns only for the collision,
# which is all the chunks use.
static func prop_at(parent: Node3D, piece: String, at: Vector3, yaw := 0.0) -> Node3D:
	var node := CryptKit.place(parent, piece, at, yaw)
	if SOLID.has(piece):
		var footprint: Vector2 = SOLID[piece]
		if int(roundf(yaw / 90.0)) % 2 != 0:
			footprint = Vector2(footprint.y, footprint.x)
		CryptKit.blocker(parent, at + Vector3(0, 1.0, 0), Vector3(footprint.x, 2.0, footprint.y))
	return node

# A fire on a stone post: a pool of light in the middle of a room.
static func brazier(parent: Node3D, at: Vector3) -> void:
	CryptKit.place(parent, "column", at)
	parent.add_child(Look.flame(at + Vector3(0, 1.55, 0), 2.2))
	var light := Look.torch_light(2.6, 8.0)
	light.shadow_enabled = false
	light.position = at + Vector3(0, 2.3, 0)
	parent.add_child(light)
	CryptKit.blocker(parent, at + Vector3(0, 0.7, 0), Vector3(0.7, 1.4, 0.7))
