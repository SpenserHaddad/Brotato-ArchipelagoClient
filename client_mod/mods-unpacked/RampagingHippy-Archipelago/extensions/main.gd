extends "res://main.gd"

const LOG_NAME = "RampagingHippy-Archipelago/main"

var _ap_gift_common = preload("res://mods-unpacked/RampagingHippy-Archipelago/content/consumables/ap_gift_items/ap_gift_item_common.tres")
var _ap_gift_uncommon = preload("res://mods-unpacked/RampagingHippy-Archipelago/content/consumables/ap_gift_items/ap_gift_item_uncommon.tres")
var _ap_gift_rare = preload("res://mods-unpacked/RampagingHippy-Archipelago/content/consumables/ap_gift_items/ap_gift_item_rare.tres")
var _ap_gift_legendary = preload("res://mods-unpacked/RampagingHippy-Archipelago/content/consumables/ap_gift_items/ap_gift_item_legendary.tres")

onready var ap_upgrade_to_process_icons = {
	Tier.COMMON: preload("res://mods-unpacked/RampagingHippy-Archipelago/images/ap_logo_100_gift_upgrade_common.png"),
	Tier.UNCOMMON: preload("res://mods-unpacked/RampagingHippy-Archipelago/images/ap_logo_100_gift_upgrade_uncommon.png"),
	Tier.RARE: preload("res://mods-unpacked/RampagingHippy-Archipelago/images/ap_logo_100_gift_upgrade_rare.png"),
	Tier.LEGENDARY: preload("res://mods-unpacked/RampagingHippy-Archipelago/images/ap_logo_100_gift_upgrade_legendary.png"),
}

# Extensions
var _drop_ap_pickup = true
onready var _ap_client
onready var _life_container_p1 = $UI/HUD/LifeContainerP1 # Show AP progress under player 1

func _ready() -> void:
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client
	
	if _ap_client.connected_to_multiworld():
		if RunData.current_wave == DebugService.starting_wave:
			# Run started, notify the AP game state tracker
			var active_characters = []
			for player in RunData.players_data:
				active_characters.append(player.current_character.my_id)
			_ap_client.game_state.notify_run_started(active_characters)
			
		# Give player any unprocessed items and upgrades from the multiworld
		for item_tier in _ap_client.items_progress.received_items_by_tier:
			var items_received = _ap_client.items_progress.received_items_by_tier[item_tier]
			var items_processed = _ap_client.items_progress.processed_items_by_tier[item_tier]
			# Check if there's items to process first to avoid log noise.
			if items_received > items_processed:
				var items_to_process = items_received - items_processed;
				ModLoaderLog.debug("Giving player %d items of tier %d." % [items_to_process, item_tier], LOG_NAME)
				for _i in range(items_to_process):
					_on_ap_item_received(item_tier)

		for upgrade_tier in _ap_client.upgrades_progress.received_upgrades_by_tier:
			var upgrades_received = _ap_client.upgrades_progress.received_upgrades_by_tier[upgrade_tier]
			var upgrades_processed = _ap_client.upgrades_progress.processed_upgrades_by_tier[upgrade_tier]
			if upgrades_received > upgrades_processed:
				var upgrades_to_process = upgrades_received - upgrades_processed
				ModLoaderLog.debug("Giving player %d upgrades of tier %d." % [upgrades_to_process, upgrade_tier], LOG_NAME)
				for _i in range(upgrades_to_process):
					_on_ap_upgrade_received(upgrade_tier)

		# Need to call after run is started otherwise some game state isn't ready yet.
		_ap_client.game_state.notify_wave_started(RunData.current_wave)
		
		var _status = _ap_client.items_progress.connect("item_received", self, "_on_ap_item_received")
		_status = _ap_client.upgrades_progress.connect("upgrade_received", self, "_on_ap_upgrade_received")
		
		ModLoaderMod.append_node_in_scene(
			self,
			"ApLootCrateProgress",
			_life_container_p1.get_path(),
			"res://mods-unpacked/RampagingHippy-Archipelago/ui/menus/hud/ap_hud.tscn",
			true
		)

# Archipelago Item received handlers
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

	# Adapted from on_consumable_picked_up
	for player_index in range(RunData.get_player_count()):
		var item_to_process = UpgradesUI.ConsumableToProcess.new()
		item_to_process.consumable_data = item_data
		item_to_process.player_index = player_index
		_consumables_to_process[player_index].push_back(item_to_process)
		_things_to_process_player_containers[player_index].consumables.add_element(item_data)

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
	# Adapted from on_levelled_up
	var upgrade_icon = ap_upgrade_to_process_icons[upgrade_tier]
	for player_index in range(RunData.get_player_count()):
		_things_to_process_player_containers[player_index].upgrades.add_element(upgrade_icon, upgrade_level)
		var upgrade_to_process = UpgradesUI.UpgradeToProcess.new()
		upgrade_to_process.level = upgrade_level
		upgrade_to_process.player_index = player_index
		_upgrades_to_process[player_index].push_back(upgrade_to_process)
	# Mark the upgrade as processed here insteard of where it's actually
	# processed in _on_EndWaveTimer_timeout. It's a lot simpler to do here and
	# the end result is the same either way.
	_ap_client.upgrades_progress.process_ap_upgrade(upgrade_tier)

# Base overrides
func spawn_consumables(unit: Unit) -> void:
	# No reason to check if connected to the multiworld, this is vanilla if
	# we're not connected since the game should never drop ap_pickups otherwise.
	var consumable_count_start = _consumables.size()
	if _ap_client.debug.auto_spawn_loot_crate:
		var old_unit_always_drop_consumable = unit.stats.always_drop_consumables
		if _ap_client.debug.auto_spawn_loot_crate_counter == _ap_client.debug.auto_spawn_loot_crate_on_count:
			_ap_client.debug.auto_spawn_loot_crate_counter = 0
			ModLoaderLog.debug("Debug spawning consumable", LOG_NAME)
			unit.stats.always_drop_consumables = true
		else:
			_ap_client.debug.auto_spawn_loot_crate_counter += 1
		.spawn_consumables(unit)
		unit.stats.always_drop_consumables = old_unit_always_drop_consumable
	else:
		.spawn_consumables(unit)

	var consumable_count_after = _consumables.size()
	var spawned_consumable = consumable_count_after > consumable_count_start
	if spawned_consumable:
		var spawned_consumable_id = _consumables.back().consumable_data.my_id
		if spawned_consumable_id == "ap_pickup":
			_ap_client.common_loot_crate_progress.notify_crate_spawned()
		elif spawned_consumable_id == "ap_legendary_pickup":
			_ap_client.legendary_loot_crate_progress.notify_crate_spawned()

func on_consumable_picked_up(consumable: Node, player_index: int) -> void:
	var is_ap_consumable = false
	if consumable.consumable_data.my_id == "ap_pickup":
		ModLoaderLog.debug("Picked up AP consumable", LOG_NAME)
		is_ap_consumable = true
		_ap_client.common_loot_crate_progress.notify_crate_picked_up()
	elif consumable.consumable_data.my_id == "ap_legendary_pickup":
		ModLoaderLog.debug("Picked up legendary AP consumable", LOG_NAME)
		is_ap_consumable = true
		_ap_client.legendary_loot_crate_progress.notify_crate_picked_up()

	if is_ap_consumable:
		# Pretend we're a crate and add gold if the player has Bag, copy/pasted from the
		# base function.
		var item_box_gold_effect = RunData.get_player_effect("item_box_gold", player_index)
		if item_box_gold_effect != 0:
			RunData.add_gold(item_box_gold_effect, player_index)
			RunData.add_tracked_value(player_index, "item_bag", item_box_gold_effect)
	.on_consumable_picked_up(consumable, player_index)

func clean_up_room(is_last_wave: bool = false, is_run_lost: bool = false, is_run_won: bool = false) -> void:
	_ap_client.game_state.notify_wave_finished(RunData.current_wave, is_run_lost, is_run_won)
	# Exactly one of these will be set when the run is completed. Can't trust
	# is_last_wave since it might be false on wave 20 if endless mode is selected.
	if is_run_won or is_run_lost:
		_ap_client.game_state.notify_run_finished(is_run_won)
	.clean_up_room(is_last_wave, is_run_lost, is_run_won)
