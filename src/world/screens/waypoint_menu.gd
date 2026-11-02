class_name WaypointMenu
extends WorldScreen
# Every waypoint in order, the known ones lit. Choosing one takes you there; the screen fades with the
# world rather than closing, so the world never shows through between.

var here := ""
var menu := MenuList.new()

func _init(current_zone := "") -> void:
	super()
	here = current_zone
	title = "Waypoints"
	name = "WaypointMenu"

func _build() -> void:
	for entry: Array in ZoneLibrary.WAYPOINTS:
		var zone_id: String = entry[0]
		var known := zone_id in Session.waypoints
		var label: String = entry[1] if known else "Undiscovered"
		if zone_id == here:
			label += "  (here)"
		menu.add_item(label, func() -> void: travel(zone_id), known and zone_id != here)
	body.add_child(menu)
	if menu._enabled().is_empty():
		var none := UiTheme.text("Find more waypoints out in the dark.", 28, UiTheme.FADED)
		none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.add_child(none)
	menu.take_focus()

func _prompts() -> Array:
	return [["a", "Travel"], ["b", "Back"]] if not menu._enabled().is_empty() else [["b", "Back"]]

func travel(zone_id: String) -> void:
	if not is_open:
		return
	is_open = false
	Sound.play("waypoint")
	Travel.go(zone_id, "waypoint")
