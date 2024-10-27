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
		for character_id in character_ids:
			var character_name = constants.CHARACTER_ID_TO_NAME[character_id]
			var character_won_loc_name = constants.RUN_COMPLETE_LOCATION_TEMPLATE.format({"char": character_name})
			var character_won_loc_id = _ap_client.data_package.location_name_to_id[character_won_loc_name]
			_ap_client.check_location(character_won_loc_id)

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
	
	var client_status  = _ap_client.get_value(["client_status_%d_%d" % [_ap_client.team, _ap_client.slot]])
	has_won_multiworld = client_status == ApTypes.ClientStatus.CLIENT_GOAL
