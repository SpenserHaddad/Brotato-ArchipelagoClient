class_name ApSettingsContainer
extends PanelContainer

export (String) var title
export (String) var tooltip

onready var _container: HBoxContainer = $HBoxContainer
onready var _label: Button = $HBoxContainer / Label
onready var _value: Label = $HBoxContainer / Value

var color_override: Color = Color.black

func _ready():
	if color_override != Color.black:
		_label.add_color_override("font_color", color_override)
		_value.add_color_override("font_color", color_override)
	else:
		_label.add_color_override("font_color", Color.white)
		_value.add_color_override("font_color", Color.white)
		
	init_label_focus()
	_label.text = title
	
	if tooltip:
		_container.hint_tooltip = tooltip

func set_value(value: String):
	_value.text = value

func enable_focus() -> void :
	focus_mode = FOCUS_ALL

func disable_focus() -> void :
	focus_mode = FOCUS_NONE

func init_label_focus() -> void :
	_label.focus_mode = FOCUS_NONE
	_label.mouse_filter = MOUSE_FILTER_PASS

func _on_container_focus_entered():
	_on_focused_or_hovered("focused", self)


func _on_container_focus_exited():
	_on_unfocused_or_unhovered("unfocused", self)


func _on_Label_mouse_entered():
	_on_focused_or_hovered("hovered", _label)


func _on_Label_mouse_exited():
	_on_unfocused_or_unhovered("unhovered", _label)


func _on_Label_focus_entered():
	_on_focused_or_hovered("focused", _label)


func _on_Label_focus_exited():
	_on_unfocused_or_unhovered("unfocused", _label)


func _on_focused_or_hovered(signal_name: String, target: Control):
	_apply_focus_theme(0)


func _on_unfocused_or_unhovered(signal_name: String, target: Control):
	remove_stylebox_override("panel")


func _apply_focus_theme(player_index: int) -> void :
	var stylebox_override: = get_stylebox("panel").duplicate()
	stylebox_override.border_color = _label.get_color("font_color")
	add_stylebox_override("panel", stylebox_override)
