extends "res://ui/menus/ingame/upgrades_ui.gd"

onready var _title: Label = $MarginContainer/Content/VBoxContainer/Title

var _ap_client
var _default_title_text

func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client
	_default_title_text = _title.text

func show_upgrade_option(level_or_ap_arr) -> void:
	var level: int
	if level_or_ap_arr is Array:
		level = level_or_ap_arr[0]
		var tier: int = level_or_ap_arr[1]
		var tier_str: String = _tier_to_str(tier)
		_title.text = "AP % Upgrade" % tier_str
	else:
		level = level_or_ap_arr
		_title.text = _default_title_text

	.show_upgrade_options(level)

func _tier_to_str(tier: int) -> String:
	match tier:
		Tier.COMMON:
			return "Common"
		Tier.UNCOMMON:
			return "Uncommon"
		Tier.RARE:
			return "Rare"
		Tier.LEGENDARY:
			return "Legendary"
		_:
			# Unreachable unless new tier defintions are added
			return "<unknown tier>"
