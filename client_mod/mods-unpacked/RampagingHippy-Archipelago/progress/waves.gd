## Track waves completed by the player and send corresponding checks to the multiworld.
##
## Brotato Archipelago defines locations for every n'th wave completed with a each 
## character. The wave counts are determined at generation time and stored in slot_data,
## which this class reads when connecting to the multiworld.
##
## This then listens for every wave to be completed and sends a check if the completed 
## wave corresponds to one.
extends "res://mods-unpacked/RampagingHippy-Archipelago/progress/_base.gd"
class_name ApWavesProgress

var waves_with_checks: PoolIntArray

func _init(ap_client, game_state).(ap_client, game_state):
	var _status = _game_state.connect("wave_finished", self, "_on_wave_finished")

func on_connected_to_multiworld():
	waves_with_checks = PoolIntArray(_ap_client.slot_data["waves_with_checks"])

func _on_wave_finished(wave_number: int, character_ids: Array, is_run_lost: bool, is_run_won: bool):
	if not is_run_lost and waves_with_checks.has(wave_number):
		# TODO: check if location was checked already
		for character_id in character_ids:
			# Register that the wave was won with each character (in case of co-op)
			var character_name = constants.CHARACTER_ID_TO_NAME[character_id]
			var location_name = "Wave %d Completed (%s)" % [wave_number, character_name]
			var location_id = _ap_client.data_package.location_name_to_id[location_name]
			if _ap_client.missing_locations.has(location_id):
				_ap_client.check_location(location_id)
