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
const LOG_NAME = "RampagingHippy-Archipelago/progress/waves"

var waves_with_checks: PoolIntArray

func _init(ap_client, game_state).(ap_client, game_state):
	pass

func on_connected_to_multiworld():
	waves_with_checks = PoolIntArray(_ap_client.slot_data["waves_with_checks"])

func on_wave_finished(wave_number: int, character_ids: Array, is_run_lost: bool, _is_run_won: bool):
	ModLoaderLog.info("Wave %d completed: characters=%s, is_run_lost=%s, is_run_won=%s" %
		[wave_number, ", ".join(character_ids), is_run_lost, _is_run_won], LOG_NAME)
	if not is_run_lost and waves_with_checks.has(wave_number):
		# TODO: check if location was checked already
		for character_id in character_ids:
			# Register that the wave was won with each character (in case of co-op)
			var character_name = constants.CHARACTER_ID_TO_NAME[character_id]
			var location_name = "Wave %d Completed (%s)" % [wave_number, character_name]
			var location_id = _ap_client.data_package.location_name_to_id[location_name]
			if _ap_client.missing_locations.has(location_id):
				ModLoaderLog.info("Sending location check %s" % location_name, LOG_NAME)
				_ap_client.check_location(location_id)
			else:
				ModLoaderLog.info("Location %s already checked, not sending check." % location_name, LOG_NAME)
