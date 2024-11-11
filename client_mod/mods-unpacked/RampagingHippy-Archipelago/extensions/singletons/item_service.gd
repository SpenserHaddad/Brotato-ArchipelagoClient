extends "res://singletons/item_service.gd"

const LOG_NAME = "RampagingHippy-Archipelago/item_service"
const ITEM_BOX_ID = "consumable_item_box"
const LEGENDARY_ITEM_BOX_ID = "consumable_legendary_item_box"

var _ap_normal_consuamble = preload("res://mods-unpacked/RampagingHippy-Archipelago/content/consumables/ap_pickup/ap_pickup.tres")
var _ap_legendary_consumable = preload("res://mods-unpacked/RampagingHippy-Archipelago/content/consumables/ap_legendary_pickup/ap_legendary_pickup.tres")


onready var _ap_client
onready var _base_game_item_box
onready var _base_game_legendary_item_box

func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client

	for consumable in consumables:
		if consumable.my_id == ITEM_BOX_ID:
			_base_game_item_box = consumable
		elif consumable.my_id == LEGENDARY_ITEM_BOX_ID:
			_base_game_legendary_item_box = consumable

func get_consumable_for_tier(tier: int = Tier.COMMON) -> ConsumableData:
	# Have the game choose what it would spawn first then check it. If it's a
	# crate drop, and we have space for an AP drop, replace it with the
	# corresponding AP consumable.
	# This is only called when the game would actually spawn a consumable, which
	# makes this the earliest possible place we can override the behavior. This
	# is good; it means we have to change the minimum real game behavior.
	# Further, this call is only getting the data about what to spawn, the
	# actual instance is created later, so we can just drop the original return
	# value if necessary without hurting anything.
	var consumable
	if _ap_client.debug.enable_auto_spawn_loot_crate and _ap_client.debug.auto_spawn_loot_crate:
		# Debug tool is tellng is to forcibly drop an item box, ignore base game path
		if tier == Tier.LEGENDARY:
			consumable = _base_game_legendary_item_box
		else:
			consumable = _base_game_item_box
	else:
		consumable = .get_consumable_for_tier(tier)

	# Replace with corrsponding AP item if possible
	if _ap_client.common_loot_crate_progress.can_spawn_consumable and consumable.my_id == ITEM_BOX_ID:
		return _ap_normal_consuamble.duplicate()
	elif _ap_client.legendary_loot_crate_progress.can_spawn_consumable and consumable.my_id == LEGENDARY_ITEM_BOX_ID:
		return _ap_legendary_consumable.duplicate()
	else:
		return consumable

func process_item_box(consumable_data: ConsumableData, wave: int, player_index: int) -> ItemParentData:
	match consumable_data.my_id:
		"ap_gift_item_common", "ap_gift_item_uncommon", "ap_gift_item_rare", "ap_gift_item_legendary":
			var item_tier = consumable_data.tier
			var item_wave = _ap_client.items_progress.process_ap_item(item_tier, player_index)
			ModLoaderLog.debug(
				"Processing AP item of tier %d at wave %d for player %d" 
				% [item_tier, item_wave, player_index], 
				LOG_NAME
			)
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

func get_player_shop_items(wave: int, player_index: int, args: ItemServiceGetShopItemsArgs) -> Array:
	if _ap_client.connected_to_multiworld():
		ModLoaderLog.debug("Get shop items called with: wave=%d, player_index=%d, args=%s" % [wave, player_index, args], LOG_NAME)
		var ap_num_shop_slots = _ap_client.shop_slots_progress.num_unlocked_shop_slots
		var num_locked_items = args.locked_items.size()
		if num_locked_items > 0:
			# We're rerolling the shop with some slots locked, make sure we don't accidentally add slots
			args.count = int(min(args.count, ap_num_shop_slots - num_locked_items))
		elif args.count > ap_num_shop_slots:
			args.count = ap_num_shop_slots
		ModLoaderLog.debug("Calling get_player_shop_items base with args.count=%d" % args.count, LOG_NAME)
	
	return .get_player_shop_items(wave, player_index, args)
