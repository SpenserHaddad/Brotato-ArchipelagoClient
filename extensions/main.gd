extends "res://main.gd"

# Extensions
var _drop_ap_pickup = true;
onready var _brotato_client

func _ready() -> void:
	ModLoaderLog.info("AP main ready", ArchipelagoModBase.MOD_NAME)
	var mod_node: ArchipelagoModBase = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_brotato_client = mod_node.brotato_client
	var _status = _brotato_client.connect("xp_received", RunData, "add_xp")
	_status = _brotato_client.connect("gold_received", RunData, "add_gold")


#func spawn_consumables(unit: Unit) -> void:
#	if _drop_ap_pickup:
#		ModLoaderLog.debug("DROP AP ITEM", ArchipelagoModBase.MOD_NAME)
#		_drop_ap_pickup = false
#	.spawn_consumables(unit)
#
#func clean_up_room(is_last_wave: bool = false, is_run_lost: bool = false, is_run_won: bool =false) -> void:
#	ModLoaderLog.debug("Resetting drop_item_check", ArchipelagoModBase.MOD_NAME)
#	_drop_ap_pickup = false
#	.clean_up_room(is_last_wave, is_run_lost, is_run_won)

# Custom
# =============================================================================

func on_consumable_picked_up(consumable: Node):
	if consumable.consumable_data.my_id.begins_with("ap_item"):
		ModLoaderLog.info("Picked up AP consumable", ArchipelagoModBase.MOD_NAME)
		_brotato_client.item_picked_up(consumable, Tier.COMMON)
	.on_consumable_picked_up(consumable)
	
