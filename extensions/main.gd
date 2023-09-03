extends "res://main.gd"

# Extensions
var _drop_ap_pickup = true;

func _ready() -> void:
	ModLoaderLog.info("AP main ready", ArchipelagoModBase.MOD_NAME)

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
