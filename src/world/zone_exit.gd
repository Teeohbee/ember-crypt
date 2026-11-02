class_name ZoneExit
extends Interactable
# A way through to the next zone - the town gate, the crypt stairs. A takes you; arrival tells the
# zone on the other side which end you came out of.

var target := ""
var arrival := ""

func _init(words: String, to_zone: String, arriving_at: String, within := 3.0) -> void:
	super(words, within)
	target = to_zone
	arrival = arriving_at
	name = "ExitTo" + to_zone.to_pascal_case()
	used.connect(func(_hero: Hero) -> void:
		Sound.play("select")
		Travel.go(target, arrival))
