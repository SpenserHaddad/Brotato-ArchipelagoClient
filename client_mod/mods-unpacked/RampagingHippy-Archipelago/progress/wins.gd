## Send checks when runs are won, and set the goal when the player has enough wins.
##
## Listens for every run to be won and sends the appropriate check for the winning
## character.
##
## Also listens for every "Run Won" item to be received. When enough are received, sets
## the player's status as CLIENT_GOAL, indicating they've completed their goal.
extends "res://mods-unpacked/RampagingHippy-Archipelago/progress/_base.gd"
class_name ApWinsProgress

var ApTypes = load("res://mods-unpacked/RampagingHippy-Archipelago/ap/ap_types.gd")

const LOG_NAME = "RampagingHippy-Archipelago/progress/wins"

var has_won_multiworld: bool = false
var wins_for_goal: int
var num_wins: int = 0
var characters_won_with: PoolStringArray = []

func _init(ap_client, game_state).(ap_client, game_state):
	var _status = _game_state.connect("wave_finished", self, "_on_wave_finished")

func _on_wave_finished(wave_number: int, character_ids: Array, is_run_lost: bool, _is_run_won: bool):
	# Use wave_number and is_run_lost to decide if we won the run or not, in 
	# case the player went into endless mode. is_run_lost=false means the wave
	# ended with either a victory or going into endless mode, both of which
	# count as a win for AP.
	if wave_number == 20 and not is_run_lost:
		# Run won, give a win for each character won with (in case of co-op)
		ModLoaderLog.info("Run won, sending location checks for all characters.", LOG_NAME)
		for character_id in character_ids:
			var character_name = constants.CHARACTER_ID_TO_NAME[character_id]
			var character_won_loc_name = constants.RUN_COMPLETE_LOCATION_TEMPLATE.format({"char": character_name})
			var character_won_loc_id = _ap_client.data_package.location_name_to_id[character_won_loc_name]
			if _ap_client.missing_locations.has(location_id):
				ModLoaderLog.info("Sending location check for %s" % character_won_loc_name, LOG_NAME)
				_ap_client.check_location(character_won_loc_id)
			else:
				ModLoaderLog.info("Location %s already checked, not sending check." % character_won_loc_name, LOG_NAME)

func on_item_received(item_name: String, _item):
	if item_name == "Run Won":
		num_wins += 1
		if num_wins >= wins_for_goal and not has_won_multiworld:
			_ap_client.set_status(ApTypes.ClientStatus.CLIENT_GOAL)
			# Set this so we don't set the status multiple times when connecting to a won slot.
			has_won_multiworld = true

func on_connected_to_multiworld():
	wins_for_goal = _ap_client.slot_data["num_wins_needed"]
	num_wins = 0
	characters_won_with = []
	
	# Hotfix: Clamp the number of wins needed to the number of character "Run
	# Won" locations available in the data package. This fixes a bug in the
	# apworld logic that allowed the game to state more wins were needed to goal
	# in the slot data than there could be characters available, depending on
	# DLC available. This hopefully should be resolved and removable in a future
	# release, but for now it makes sure some broken games are winnable.
	# Duplicate the logic from ./characters.gd so we don't need to figure out
	# order of resolution here.
	if ProgressData.available_dlcs.empty():
		# We're guaranteed by the apworld to have enough characters to win with
		# if Abyssal Terrors is installed, otherwise we need to detect the bug.
		# Other bug: The four 1.1.0.0 base game characters were incorrectly
		# listed as DLC characters in the apworld,so their checks are not
		# defined if the DLC option was not enabled.
		var num_characters = ItemService.characters.size()
		var ap_world_num_base_game_characters = num_characters - 4
		if wins_for_goal > ap_world_num_base_game_characters:
			ModLoaderLog.warning("Bug detected, not enough characters to win with without DLC. Updating value", LOG_NAME)
			wins_for_goal = ap_world_num_base_game_characters

	var client_status  = _ap_client.get_value(["client_status_%d_%d" % [_ap_client.team, _ap_client.slot]])
	has_won_multiworld = client_status == ApTypes.ClientStatus.CLIENT_GOAL
