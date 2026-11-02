class_name ConfirmBox
extends PanelContainer
# "Are you sure?" with two choices. Focus starts on the safe one, and B means no.

signal answered(yes: bool)

var _question := UiTheme.heading("", 40, UiTheme.PARCHMENT)
var _menu := MenuList.new()
var _on_yes := Callable()
var _no: Button
var _yes: Button

func _ready() -> void:
	custom_minimum_size.x = 640
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	add_child(column)
	column.add_child(_question)
	column.add_child(UiTheme.divider(480))
	_no = _menu.add_item("Stay", func() -> void: _answer(false))
	_yes = _menu.add_item("Leave", func() -> void: _answer(true))
	column.add_child(_menu)

# The answers default to Stay / Leave; a screen asking something else names its own
func ask(question: String, on_yes: Callable, yes_label := "Leave", no_label := "Stay") -> void:
	_question.text = question
	_yes.text = yes_label
	_no.text = no_label
	_on_yes = on_yes
	show()
	_menu.reset()
	_menu.take_focus()

func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Sound.play("back")
		_answer(false)

func _answer(yes: bool) -> void:
	hide()
	answered.emit(yes)
	if yes:
		_on_yes.call()
