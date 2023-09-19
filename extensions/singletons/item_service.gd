extends "res://singletons/item_service.gd"

onready var _ap_item
onready var _ap_legendary_item
onready var _ap_consumable
onready var _ap_legendary_consumable
onready var _brotato_client: BrotatoApAdapter

func _ready():
	_brotato_client = get_node("/root/ModLoader/RampagingHippy-Archipelago").brotato_client
	_ap_consumable = load("res://mods-unpacked/RampagingHippy-Archipelago/content/consumables/ap_pickup.tres")
	_ap_item = load("res://mods-unpacked/RampagingHippy-Archipelago/content/items/ap_item/ap_item_data.tres")
	ModLoaderLog.debug("Loaded AP items", ArchipelagoModBase.MOD_NAME)	

# TODO: Drop on loot crate instead?
func get_consumable_to_drop(tier:int = Tier.COMMON) -> ConsumableData:
	if tier == Tier.LEGENDARY and _brotato_client.can_drop_legendary_consumable():
		ModLoaderLog.debug("Dropping legendary AP item.", ArchipelagoModBase.MOD_NAME)
		return _ap_legendary_consumable
	elif _brotato_client.can_drop_consumable():
		ModLoaderLog.debug("Dropping normal AP item for wave.", ArchipelagoModBase.MOD_NAME)
		return _ap_consumable
	else:
		return .get_consumable_to_drop(tier)

func process_item_box(wave:int, consumable_data:ConsumableData, fixed_tier:int = - 1) -> ItemParentData:
		ModLoaderLog.debug_json_print("Processing box %s:" % consumable_data.my_id, consumable_data, ArchipelagoModBase.MOD_NAME)
		if consumable_data.my_id == "ap_pickup":
			ModLoaderLog.debug("Picked up AP consumable", ArchipelagoModBase.MOD_NAME)
			_brotato_client.consumable_picked_up()
			return _ap_item
		elif consumable_data.my_id == "ap_legendary_pickup":
			ModLoaderLog.debug("Picked up legendary AP consumable", ArchipelagoModBase.MOD_NAME)
			_brotato_client.legendary_consumable_picked_up()
			return _ap_legendary_item
		return .process_item_box(wave, consumable_data, fixed_tier)
