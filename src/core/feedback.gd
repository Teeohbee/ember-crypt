extends Node
# Hit feel lives here: every hit Combat lands comes through hit(), so hit-stop, shake, damage numbers
# and flashes are tuned in one place. M1 fills these in; until then they do nothing, so the rest of the
# game can call them freely.

func hit(_event: DamageEvent) -> void:
	pass

# Freezes the action for a moment, so a heavy blow lands
func hit_stop(_seconds: float) -> void:
	pass

# Kicks the camera; strength 0-1
func shake(_strength: float) -> void:
	pass

# A number (or word) that pops off a point in the world
func number(_at: Vector3, _text: String, _colour := Color.WHITE, _big := false) -> void:
	pass
