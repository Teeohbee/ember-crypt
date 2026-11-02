class_name RoomChunk
extends Resource
# One hand-authored room for the dungeon generator: what's in it, not its walls. Every room has the
# same 5 x 5 tile footprint (20 m square, centred on the origin); the builder adds the walls and opens
# a doorway in the middle of each side that leads somewhere. So props have to keep clear of the four
# doorway lanes (the cross through the middle, near the walls). Adding a room means adding one of
# these, not code.

@export var id: StringName
# What it can be used for: start, fight, boss
@export var kinds: PackedStringArray = ["fight"]
@export var weight := 10
# Each [piece name, position in metres from the room's centre, yaw in degrees]
@export var props: Array = []
# Where monster packs stand, metres from the centre
@export var packs: PackedVector3Array = []
@export var pack_size := 3
# Free-standing fires (braziers, candles) that light the room, metres from the centre
@export var fires: PackedVector3Array = []
# Fraction of floor tiles laid as the rubble-strewn kind
@export var rubble := 0.18
