extends "res://ui/menus/run/locked_panel.gd"

const LOG_NAME = "RampagingHippy-Archipelago/extensions/ui/menus/run/locked_panel"
const BrotatoApConstants = preload("res://mods-unpacked/RampagingHippy-Archipelago/ap/constants.gd")

var _ap_client
var _constants

func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client
	_constants = BrotatoApConstants.new()

func set_element(element: ItemParentData, type: int) -> void:
	.set_element(element, type)

	if type == RewardType.CHARACTER and _ap_client.connected_to_multiworld():
		_description.text = "Missing AP item for %s" % _constants.CHARACTER_ID_TO_NAME.get(element.my_id)