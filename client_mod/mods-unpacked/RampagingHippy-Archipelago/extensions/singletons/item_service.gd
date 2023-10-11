extends "res://singletons/item_service.gd"

const LOG_NAME = "RampagingHippy-Archipelago/item_service"

var _ap_pickup = preload("res://mods-unpacked/RampagingHippy-Archipelago/content/consumables/ap_pickup/ap_pickup.tres")
var _ap_legendary_pickup = preload("res://mods-unpacked/RampagingHippy-Archipelago/content/consumables/ap_legendary_pickup/ap_legendary_pickup.tres")
onready var _item_box_original
onready var _legendary_item_box_original
onready var _brotato_client

func _ready():
	_brotato_client = get_node("/root/ModLoader/RampagingHippy-Archipelago").brotato_client
	var _success = _brotato_client.connect("crate_drop_status_changed", self, "_on_crate_drop_status_changed")
	_success = _brotato_client.connect("legendary_crate_drop_status_changed", self, "_on_legendary_crate_drop_status_changed")
	_item_box_original = item_box
	_legendary_item_box_original = legendary_item_box

func _on_crate_drop_status_changed(can_drop_ap_pickups: bool):
	if can_drop_ap_pickups:
		ModLoaderLog.debug("Crate is AP consumable", LOG_NAME)
		item_box = _ap_pickup
	else:
		ModLoaderLog.debug("Crate is normal crate.", LOG_NAME)
		item_box = _item_box_original

func _on_legendary_crate_drop_status_changed(can_drop_ap_legendary_pickups: bool):
	if can_drop_ap_legendary_pickups:
		legendary_item_box = _ap_legendary_pickup
	else:
		legendary_item_box = _legendary_item_box_original		

func process_item_box(wave:int, consumable_data: ConsumableData, fixed_tier: int = - 1) -> ItemParentData:
		ModLoaderLog.debug("Processing box %s:" % consumable_data.my_id, LOG_NAME)
		match consumable_data.my_id:			
			"ap_gift_item_common", "ap_gift_item_uncommon", "ap_gift_item_rare", "ap_gift_item_legendary":
				var gift_tier = consumable_data.tier
				ModLoaderLog.debug("Processing gift item of tier %d" % gift_tier, LOG_NAME)
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

func get_shop_items(wave: int, number: int = NB_SHOP_ITEMS, shop_items: Array = [], locked_items: Array = []) -> Array:
	ModLoaderLog.debug("Get shop items called with: wave=%d, number=%d, shop_items=%s, locked_items=%s" % [wave, number, shop_items, locked_items], LOG_NAME)
	var ap_num_shop_slots = _brotato_client.get_num_shop_slots()
	var num_locked_items = locked_items.size()
	if num_locked_items > 0:
		# We're rerolling the shop with some slots locked, make sure we don't accidentally add slots
		number = min(number, ap_num_shop_slots - num_locked_items)
	elif number > ap_num_shop_slots:
		number = ap_num_shop_slots
	ModLoaderLog.debug("Calling get_shop_items base with number=%d" % number, LOG_NAME)
	return .get_shop_items(wave, number, shop_items, locked_items)
