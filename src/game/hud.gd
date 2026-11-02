class_name Hud
extends CanvasLayer
# One player's heads-up display. Milestones add their widgets (globes, skill bar, pickup popup, XP bar)
# as children here, each widget taking the slot's hero.

var slot: PlayerSlot

func _init(player_slot: PlayerSlot) -> void:
	slot = player_slot
	name = "Hud%d" % player_slot.index
	layer = 10

func hero() -> Hero:
	return slot.hero
