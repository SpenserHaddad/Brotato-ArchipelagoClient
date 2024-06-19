extends "res://singletons/item_service.gd"

const LOG_NAME = "RampagingHippy-Archipelago/item_service"

var _ap_pickup = preload ("res://mods-unpacked/RampagingHippy-Archipelago/content/consumables/ap_pickup/ap_pickup.tres")
var _ap_legendary_pickup = preload ("res://mods-unpacked/RampagingHippy-Archipelago/content/consumables/ap_legendary_pickup/ap_legendary_pickup.tres")
onready var _item_box_original
onready var _legendary_item_box_original
onready var _ap_client

func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client
	var _success = _ap_client.common_loot_crate_progress.connect(
		"can_spawn_crate_changed",
		self,
		"_on_common_can_spawn_crate_changed"
	)
	_success = _ap_client.legendary_loot_crate_progress.connect(
		"can_spawn_crate_changed",
		self,
		"_on_legendary_can_spawn_crate_changeds"
	)
	
	_item_box_original = item_box
	_legendary_item_box_original = legendary_item_box

func _on_common_can_spawn_crate_changed(can_spawn_crate: bool, _crate_type: String):
	if can_spawn_crate:
		ModLoaderLog.debug("Crate is AP consumable", LOG_NAME)
		item_box = _ap_pickup
	else:
		ModLoaderLog.debug("Crate is normal crate.", LOG_NAME)
		item_box = _item_box_original

func _on_legendary_can_spawn_crate_changed(can_spawn_crate: bool, _crate_type: String):
	if can_spawn_crate:
		legendary_item_box = _ap_legendary_pickup
	else:
		legendary_item_box = _legendary_item_box_original

func process_item_box(wave: int, consumable_data: ConsumableData, fixed_tier: int=- 1) -> ItemParentData:
		ModLoaderLog.debug("Processing box %s:" % consumable_data.my_id, LOG_NAME)
		match consumable_data.my_id:
			"ap_gift_item_common", "ap_gift_item_uncommon", "ap_gift_item_rare", "ap_gift_item_legendary":
				var item_tier = consumable_data.tier
				ModLoaderLog.debug("Processing AP item of tier %d" % item_tier, LOG_NAME)
				var item_wave = _ap_client.items_progress.process_ap_item(item_tier)
				return .process_item_box(item_wave, consumable_data, item_tier)

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

func get_shop_items(wave: int, number: int=NB_SHOP_ITEMS, shop_items: Array=[], locked_items: Array=[]) -> Array:
	if _ap_client.connected_to_multiworld():
		ModLoaderLog.debug("Get shop items called with: wave=%d, number=%d, shop_items=%s, locked_items=%s" % [wave, number, shop_items, locked_items], LOG_NAME)
		var ap_num_shop_slots = _ap_client.shop_slots_progress.num_unlocked_shop_slots
		var num_locked_items = locked_items.size()
		if num_locked_items > 0:
			# We're rerolling the shop with some slots locked, make sure we don't accidentally add slots
			number = int(min(number, ap_num_shop_slots - num_locked_items))
		elif number > ap_num_shop_slots:
			number = ap_num_shop_slots
		ModLoaderLog.debug("Calling get_shop_items base with number=%d" % number, LOG_NAME)
	
	return .get_shop_items(wave, number, shop_items, locked_items)
