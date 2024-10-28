extends "res://ui/menus/run/character_selection_inventory.gd"

const LOG_NAME = "RampagingHippy-Archipelago/inventory_character_selection"
const BrotatoApConstants = preload("res://mods-unpacked/RampagingHippy-Archipelago/ap/constants.gd")

var _ap_client
var _constants

const ap_icon = preload("res://mods-unpacked/RampagingHippy-Archipelago/images/ap_logo_80.png")

func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client
	_constants = BrotatoApConstants.new()

func init_char_select_inventory(ap_client):
	ModLoaderLog.debug("Initializing char select inventory", LOG_NAME)
	_ap_client = ap_client
	_constants = BrotatoApConstants.new()
	
func set_elements(elements: Array, reverse_order: bool = false, replace: bool = true, prioritize_gameplay_elements: bool = false) -> void:
	.set_elements(elements, reverse_order, replace, prioritize_gameplay_elements)
	ModLoaderLog.debug("In set_elements for char_select", LOG_NAME)
	var ap_character_info = _ap_client.character_progress.character_info
	ModLoaderLog.debug("Elements: %d" % get_child_count(), LOG_NAME)
	var children = get_children()
	for child in children:
		if child.item != null:
			var character_id = _constants.CHARACTER_ID_TO_NAME.get(child.item.my_id)
			if character_id != null:
				var won_run = ap_character_info[character_id].won_run
	#			ModLoaderLog.debug("element.my_id=%s, icon=%s, is_locked=%s, won_run=%s" % [element.my_id, element.icon.load_path, element.is_locked, won_run], LOG_NAME)
				child.set_character_info(won_run)
