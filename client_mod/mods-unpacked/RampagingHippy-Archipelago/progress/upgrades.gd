## Track the number of upgrades received from items, and give them to the player.
##
## Upgrades in this case refers to the stat bonuses received when levelling up.
##
## Listen to the client for upgrades received as Archipelago items, then give them to
## the player immediately if they're in a run, or as soon as they start a new run.
##
## Upgrades are given to the player every run, so we track the total amount of items and
## give them all to the player every time they start a run.
extends "res://mods-unpacked/RampagingHippy-Archipelago/progress/_base.gd"
class_name ApUpgradesProgress

const SAVE_DATA_KEY = "progress_upgrades"

signal upgrade_received(upgrade_tier)

# The number of upgrades processed in the current run. This is set at the start of each
# run to keep track of how many upgrades each player has received from items so far so we
# can set the level of each item correctly.
var processed_upgrades_by_player_by_tier: Array

var received_upgrades_by_tier: Dictionary = {
	Tier.COMMON: 0,
	Tier.UNCOMMON: 0,
	Tier.RARE: 0,
	Tier.LEGENDARY: 0
}

func _init(ap_client, game_state).(ap_client, game_state):
	# Need this for Godot to pass through to the base class
	pass

func process_ap_upgrade(upgrade_tier: int, player_index: int):
	# Mark the upgrade as processed so we don't try to give again this run.
	processed_upgrades_by_player_by_tier[player_index][upgrade_tier] += 1

func on_item_received(item_name: String, _item):
	if item_name in constants.UPGRADE_NAME_TO_TIER:
		var upgrade_tier = constants.UPGRADE_NAME_TO_TIER[item_name]
		received_upgrades_by_tier[upgrade_tier] += 1
		
		# If we received an item, that means we're connected to a multiworld.
		# No reason to check if connected or in a run
		emit_signal("upgrade_received", upgrade_tier)

func on_connected_to_multiworld():
	# Reset the number of received upgrades in case there's data from a previous slot.
	received_upgrades_by_tier = {
		Tier.COMMON: 0,
		Tier.UNCOMMON: 0,
		Tier.RARE: 0,
		Tier.LEGENDARY: 0
	}

func on_run_started(character_ids: Array):
	# Reset the number of upgrades processed
	processed_upgrades_by_player_by_tier = []
	for _char_id in character_ids:
		processed_upgrades_by_player_by_tier.push_back(
			{
			Tier.COMMON: 0,
			Tier.UNCOMMON: 0,
			Tier.RARE: 0,
			Tier.LEGENDARY: 0
			}
		)

func export_run_specific_progress_data() -> Dictionary:
	return {
		SAVE_DATA_KEY: {
			"processed_upgrades_by_player_by_tier": processed_upgrades_by_player_by_tier.duplicate()
		}
	}
	

func load_run_specific_progress_data(data: Dictionary):
	processed_upgrades_by_player_by_tier = []
	var saved_processed_upgrades = data[SAVE_DATA_KEY]["processed_upgrades_by_player_by_tier"]
	# If the data was loaded from JSON, the keys will be strings instead of ints
	var is_string_key: bool = not saved_processed_upgrades[0].has(Tier.COMMON)
	var tier_keys = [Tier.COMMON, Tier.UNCOMMON, Tier.RARE, Tier.LEGENDARY]
	for entry in saved_processed_upgrades:
		var player_processed_upgrades = {}
		for tk in tier_keys:
			var entry_key = str(tk) if is_string_key else tk
			var tier_value = entry[entry_key]
			player_processed_upgrades[tk] = tier_value
		processed_upgrades_by_player_by_tier.push_back(player_processed_upgrades)
