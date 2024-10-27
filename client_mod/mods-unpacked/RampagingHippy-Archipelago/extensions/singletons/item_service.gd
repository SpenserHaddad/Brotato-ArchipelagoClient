extends "res://singletons/item_service.gd"

const LOG_NAME = "RampagingHippy-Archipelago/item_service"

var _ap_normal_consuamble = preload("res://mods-unpacked/RampagingHippy-Archipelago/content/consumables/ap_pickup/ap_pickup.tres")
var _ap_legendary_consumable = preload("res://mods-unpacked/RampagingHippy-Archipelago/content/consumables/ap_legendary_pickup/ap_legendary_pickup.tres")

onready var _ap_client

func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client

func get_consumable_for_tier(tier: int = Tier.COMMON) -> ConsumableData:
	if tier == Tier.LEGENDARY and _ap_client.legendary_loot_crate_progress.can_spawn_consumable:
		return _ap_legendary_consumable.duplicate()
	elif _ap_client.common_loot_crate_progress.can_spawn_consumable:
		return _ap_normal_consuamble.duplicate()
	else:
		return .get_consumable_for_tier(tier)	

func process_item_box(consumable_data: ConsumableData, wave: int, player_index: int) -> ItemParentData:
	match consumable_data.my_id:
		"ap_gift_item_common", "ap_gift_item_uncommon", "ap_gift_item_rare", "ap_gift_item_legendary":
			var item_tier = consumable_data.tier
			var item_wave = _ap_client.items_progress.process_ap_item(item_tier)
			ModLoaderLog.debug("Processing AP item of tier %d at wave %d" % [item_tier, item_wave], LOG_NAME)
			# Adapted from the base process_item_box
			var args = GetRandItemForWaveArgs.new()
			args.owned_and_shop_items = RunData.get_player_items(player_index)
			args.fixed_tier = item_tier
			return _get_rand_item_for_wave(item_wave, player_index, TierData.ITEMS, args)
		_:
			return .process_item_box(consumable_data, wave, player_index)

func get_upgrade_data(level: int, player_index: int) -> UpgradeData:
	if level >= 0:
		return .get_upgrade_data(level, player_index)
	else:
		# We set the level to -1 for AP common upgrade drops. For other tiers we can use
		# existing logic by setting the level equal to a certain multiple of 5. This way
		# we modify existing code as litle as possible. That being said, we just hard
		# code the tier for the call to get_rand_element just as the base call would do.
		return Utils.get_rand_element(_tiers_data[Tier.COMMON][TierData.UPGRADES])

func get_shop_items(wave: int, number: int = NB_SHOP_ITEMS, shop_items: Array = [], locked_items: Array = []) -> Array:
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
