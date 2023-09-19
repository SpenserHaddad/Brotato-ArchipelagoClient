extends "res://singletons/item_service.gd"

var _dropped_ap_item_wave = 0
var _ap_item_drop_count = 0
var _ap_pickup
var _ap_item

var _brotato_client: BrotatoApAdapter

func _ready():
	_brotato_client = get_node("/root/ModLoader/RampagingHippy-Archipelago").brotato_client
	_ap_pickup = load("res://mods-unpacked/RampagingHippy-Archipelago/content/consumables/ap_pickup.tres")
	_ap_item = load("res://mods-unpacked/RampagingHippy-Archipelago/content/items/ap_item/ap_item_data.tres")
	ModLoaderLog.debug("Loaded AP items", ArchipelagoModBase.MOD_NAME)	

# TODO: Drop on loot crate instead?
func get_consumable_to_drop(tier:int= Tier.COMMON) -> ConsumableData:
	if _dropped_ap_item_wave < RunData.current_wave:
		ModLoaderLog.debug("Dropping AP item for wave %d." % [RunData.current_wave],
							ArchipelagoModBase.MOD_NAME)
		_dropped_ap_item_wave = RunData.current_wave
		_ap_item_drop_count += 1
		return _ap_pickup
	else:
		return .get_consumable_to_drop(tier)

func process_item_box(wave:int, consumable_data:ConsumableData, fixed_tier:int = - 1) -> ItemParentData:
		ModLoaderLog.debug_json_print("Processing box %s:" % consumable_data.my_id, consumable_data, ArchipelagoModBase.MOD_NAME)
		if consumable_data.my_id.begins_with("ap_pickup"):
			ModLoaderLog.debug("Picked up AP consumable", ArchipelagoModBase.MOD_NAME)
			_brotato_client.item_picked_up()
			return _ap_item
		return .process_item_box(wave, consumable_data, fixed_tier)
