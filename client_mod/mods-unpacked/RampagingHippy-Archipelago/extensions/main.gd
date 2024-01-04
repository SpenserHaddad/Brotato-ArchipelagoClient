extends "res://main.gd"

const LOG_NAME = "RampagingHippy-Archipelago/main"

var _ap_gift_common = preload("res://mods-unpacked/RampagingHippy-Archipelago/content/consumables/ap_gift_items/ap_gift_item_common.tres")
var _ap_gift_uncommon = preload("res://mods-unpacked/RampagingHippy-Archipelago/content/consumables/ap_gift_items/ap_gift_item_uncommon.tres")
var _ap_gift_rare = preload("res://mods-unpacked/RampagingHippy-Archipelago/content/consumables/ap_gift_items/ap_gift_item_rare.tres")
var _ap_gift_legendary = preload("res://mods-unpacked/RampagingHippy-Archipelago/content/consumables/ap_gift_items/ap_gift_item_legendary.tres")

export (Resource) var ap_upgrade_to_process_icon = preload("res://mods-unpacked/RampagingHippy-Archipelago/ap_upgrade_icon.png")

# Extensions
var _drop_ap_pickup = true;
onready var _ap_client

func _ready() -> void:
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client
	
	if _ap_client.connected_to_multiworld():
		if RunData.current_wave == 1:
			# Run started, initialize/reset some values
			_ap_client.run_started()
			var ap_game_data = _ap_client.game_state
			ModLoaderLog.debug("Start of AP run, giving player %d XP and %d gold." % 
				[
					ap_game_data.starting_xp,
					ap_game_data.starting_gold
				],
				LOG_NAME
			)
			
			RunData.add_xp(ap_game_data.starting_xp)
			RunData.add_gold(ap_game_data.starting_gold)
			
			for gift_tier in _ap_client.game_state.received_items_by_tier:
				var num_gifts = _ap_client.game_state.received_items_by_tier[gift_tier]
				ModLoaderLog.debug("Giving player %d items of tier %d." % [num_gifts, gift_tier], LOG_NAME)
				for _i in range(num_gifts):
					_on_ap_item_received(gift_tier)

			for upgrade_tier in _ap_client.game_state.received_upgrades_by_tier:
				var num_upgrades = _ap_client.game_state.received_upgrades_by_tier[upgrade_tier]
				ModLoaderLog.debug("Giving player %d upgrades of tier %d." % [num_upgrades, upgrade_tier], LOG_NAME)
				for _i in range(num_upgrades):
					_on_ap_upgrade_received(upgrade_tier)

		# Need to call after run is started otherwise some game state isn't ready yet.
		_ap_client.wave_started()

		var _status = _ap_client.connect("xp_received", self, "_on_ap_xp_received")
		_status = _ap_client.connect("gold_received", self, "_on_ap_gold_received")
		_status = _ap_client.connect("item_received", self, "_on_ap_item_received")
		_status = _ap_client.connect("upgrade_received", self, "_on_ap_upgrade_received")

# Archipelago Item received handlers

func _on_ap_xp_received(xp_amount: int):
	ModLoaderLog.info("%d XP received" % xp_amount, LOG_NAME)
	RunData.add_xp(xp_amount)

func _on_ap_gold_received(gold_amount: int):
	ModLoaderLog.info("%d Gold received" % gold_amount, LOG_NAME)
	RunData.add_gold(gold_amount)

func _on_ap_item_received(item_tier: int):
	var item_data
	match item_tier:
		Tier.COMMON:
			item_data = _ap_gift_common
		Tier.UNCOMMON:
			item_data = _ap_gift_uncommon
		Tier.RARE:
			item_data = _ap_gift_rare
		Tier.LEGENDARY:
			item_data = _ap_gift_legendary
	_consumables_to_process.push_back(item_data)
	emit_signal("consumable_to_process_added", item_data)

func _on_ap_upgrade_received(upgrade_tier: int):
	var upgrade_level: int
	# Brotato gives items of set tiers at multiples of 5. Use this to give the correct
	# tier item without modifying the original code too much.
	match upgrade_tier:
		Tier.COMMON:
			# We override get_upgrade_data to set the tier to COMMON if the level is -1.
			upgrade_level = -1
		Tier.UNCOMMON:
			upgrade_level = 5
		Tier.RARE:
			upgrade_level = 10
		Tier.LEGENDARY:
			upgrade_level = 25
	# Taken from on_levelled_up
	emit_signal("upgrade_to_process_added", ap_upgrade_to_process_icon, upgrade_level)
	_upgrades_to_process.push_back(upgrade_level)

# Base overrides
func spawn_consumables(unit: Unit) -> void:
	if _ap_client.connected_to_multiworld():
		var consumable_count_start = _consumables.size()
		.spawn_consumables(unit)
		var consumable_count_after = _consumables.size()
		var spawned_consumable = consumable_count_after > consumable_count_start
		if spawned_consumable:
			var spawned_consumable_id = _consumables.back().consumable_data.my_id
			if spawned_consumable_id == "ap_pickup" or spawned_consumable_id == "ap_legendary_pickup":
				_ap_client.consumable_spawned()

func on_consumable_picked_up(consumable: Node) -> void:
	var is_ap_consumable = false
	if consumable.consumable_data.my_id == "ap_pickup":
		ModLoaderLog.debug("Picked up AP consumable", LOG_NAME)
		is_ap_consumable = true
		_ap_client.consumable_picked_up()
	elif consumable.consumable_data.my_id == "ap_legendary_pickup":
		ModLoaderLog.debug("Picked up legendary AP consumable", LOG_NAME)
		is_ap_consumable = true
		_ap_client.legendary_consumable_picked_up()

	if is_ap_consumable:
		# Pretend we're a crate and add gold if the player has Bag, copy/pasted from the
		# base function.
		if RunData.effects["item_box_gold"] != 0:
			RunData.add_gold(RunData.effects["item_box_gold"])
			RunData.tracked_item_effects["item_bag"] += RunData.effects["item_box_gold"]
	.on_consumable_picked_up(consumable)


func _on_WaveTimer_timeout() -> void:
	if _ap_client.connected_to_multiworld():
		_ap_client.wave_won(RunData.current_character.my_id, RunData.current_wave)
	._on_WaveTimer_timeout()

func apply_run_won():
	if _ap_client.connected_to_multiworld():
		_ap_client.run_won(RunData.current_character.my_id)
	.apply_run_won()
