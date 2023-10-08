extends "res://singletons/item_service.gd"

var _ap_item = preload("res://mods-unpacked/RampagingHippy-Archipelago/content/items/ap_item/ap_item_data.tres")
var _ap_consumable = preload("res://mods-unpacked/RampagingHippy-Archipelago/content/consumables/ap_pickup/ap_pickup.tres")
onready var _ap_legendary_item
onready var _ap_legendary_consumable
onready var _brotato_client: BrotatoApAdapter

func _ready():
	_brotato_client = get_node("/root/ModLoader/RampagingHippy-Archipelago").brotato_client
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
		ModLoaderLog.debug("Processing box %s:" % consumable_data.my_id, ArchipelagoModBase.MOD_NAME)
		match consumable_data.my_id:
			"ap_pickup":
				ModLoaderLog.debug("Picked up AP consumable", ArchipelagoModBase.MOD_NAME)
				_brotato_client.consumable_picked_up()
				return _ap_item
			
			"ap_legendary_pickup":
				ModLoaderLog.debug("Picked up legendary AP consumable", ArchipelagoModBase.MOD_NAME)
				_brotato_client.legendary_consumable_picked_up()
				return _ap_legendary_item
			
			"ap_gift_item_common", "ap_gift_item_uncommon", "ap_gift_item_rare", "ap_gift_item_legendary":
				var gift_tier = consumable_data.tier
				ModLoaderLog.debug("Processing gift item of tier %d" % gift_tier, ArchipelagoModBase.MOD_NAME)
				var gift_wave = _brotato_client.gift_item_processed(gift_tier)
				return .process_item_box(gift_wave, consumable_data, gift_tier)

			_:
				return .process_item_box(wave, consumable_data, fixed_tier)

func get_upgrade_data(level: int) -> UpgradeData:
	if level >= 0:
		return .get_upgrade_data(level)
	else:
		# We set the level to -1 for AP common upgrade drops. For other tiers we can use
		# existing logic by setting the level equal to a certain multiple of 5. This way
		# we modify existing code as litle as possible. That being said, we just hard
		# code the tier for the call to get_rand_element just as the base call would do.
		return Utils.get_rand_element(_tiers_data[Tier.COMMON][TierData.UPGRADES])
