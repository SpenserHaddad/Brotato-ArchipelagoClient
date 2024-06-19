extends Label
class_name LabelWhiteTooltip

var _tooltip_font = preload ("res://resources/fonts/actual/base/font_smallest_text.tres")
var _base_theme = preload ("res://resources/themes/base_theme.tres")

# Called when the node enters the scene tree for the first time.
func _ready():
	_tooltip_font.size = 14
	theme = _base_theme
	theme.set_color("font_color", "TooltipLabel", Color(1, 1, 1))
#	theme.set_font("", "")
#	add_color_override("font_color", Color(1,1,1))
#	var current_font = 
#	add_font_override("")
#	self.theme.set_color("font_color", "Tooltiplabel", Color(1,1,1))

func __make_custom_tooltip(for_text):
	var label = Label.new()
	label.add_font_override("", _tooltip_font)
	label.add_color_override("font_color", Color(1, 1, 1))
	
	label.text = for_text
	return label
