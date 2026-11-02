class_name HeroModel
extends Node3D
# A class's KayKit character with its weapons in hand. Each rig comes holding every prop it was
# modelled with, on BoneAttachment3Ds called handslot_r and handslot_l; all but the class's own are
# removed. Hats and capes stay. play() blends from whatever
# was playing; a one-off animation returns to idle when it finishes unless told to hold.

const HAND_SLOTS := ["handslot_r", "handslot_l"]

var hero_class: HeroClass
var animations: AnimationPlayer
var _rig: Node3D
var _holding := false

func _init(chosen: HeroClass) -> void:
	hero_class = chosen
	name = chosen.display_name
	_rig = chosen.model.instantiate()
	add_child(_rig)
	animations = _rig.find_child("AnimationPlayer", true, false)
	for slot in HAND_SLOTS:
		for prop in _rig.find_child(slot, true, false).get_children():
			if not prop.name in chosen.held:
				prop.free()
	animations.get_animation(chosen.idle).loop_mode = Animation.LOOP_LINEAR

func _ready() -> void:
	idle()
	# Start each hero at a different point in the loop, so two idling side by side don't breathe in step
	animations.seek(randf() * animations.current_animation_length, true)
	animations.animation_finished.connect(func(finished: StringName) -> void:
		if finished != StringName(hero_class.idle) and not _holding:
			idle())

func idle() -> void:
	_holding = false
	animations.play(hero_class.idle, 0.3)

func play(animation: String, blend := 0.2, hold := false) -> void:
	_holding = hold
	animations.play(animation, blend)

# Swaps whatever's in a hand for an item's model, held the way the rigs hold their own props (M4).
# null leaves the hand empty.
func hold(hand: String, base: ItemBase) -> void:
	var bone := _rig.find_child(hand, true, false)
	for prop in bone.get_children():
		prop.free()
	if base and base.model:
		var prop: Node3D = base.model.instantiate()
		prop.name = String(base.id)
		prop.transform = base.grip()
		bone.add_child(prop)

# The props in each hand, by name
func held_props() -> PackedStringArray:
	var names := PackedStringArray()
	for slot in HAND_SLOTS:
		for prop in _rig.find_child(slot, true, false).get_children():
			names.append(prop.name)
	return names
