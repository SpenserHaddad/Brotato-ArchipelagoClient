## Track waves completed by the player and the highest wave they can access.
##
## Brotato Archipelago defines locations for every n'th wave completed with a each
## character. The wave counts are determined at generation time and stored in slot_data,
## which this class reads when connecting to the multiworld.
##
## This listens for every wave to be completed and sends a check if the completed
## wave corresponds to one.
##
## In additon, this checks if the player is allowed to progress to a certain wave based
## on the wave_access slot data, which defines how many wave cap increase items are
## needed to reach a particular wave. This therefore also keeps track of the number of
## items received.
extends "res://mods-unpacked/RampagingHippy-Archipelago/progress/_base.gd"
class_name ApWavesProgress
const LOG_NAME = "RampagingHippy-Archipelago/progress/waves"

signal wave_cap_increase_received(character_name)

var waves_with_checks: PoolIntArray
var wave_cap_enabled := false
var wave_access: Dictionary
var wave_cap_increases_received := Dictionary()

func _init(ap_client, game_state).(ap_client, game_state):
	pass

func on_connected_to_multiworld():
	waves_with_checks = PoolIntArray(_ap_client.slot_data["waves_with_checks"])
	wave_access = _ap_client.slot_data.get("wave_access", {})
	wave_cap_enabled = wave_access.size() > 0
	wave_cap_increases_received.clear()

func get_wave_cap(character_id: String):
	if not wave_cap_enabled:
		return RunData.nb_of_waves
	var character_name = constants.CHARACTER_ID_TO_NAME[character_id]
	var char_wave_cap_increases_received = wave_cap_increases_received[character_name]
	for wave in range(1, RunData.nb_of_waves+1, 1):
		if wave_access[str(wave)] > char_wave_cap_increases_received:
			return wave - 1
	return RunData.nb_of_waves

func can_play_wave(wave_number: int, character_name: String):
	if not wave_cap_enabled:
		return true
	var cap_increases_received_for_character = wave_cap_increases_received.get(character_name, 0)
	return cap_increases_received_for_character >= wave_access[str(wave_number)]

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

func on_item_received(item_name: String, _item):
	if item_name.begins_with("Progressive Wave Cap"):
		# Extract character name from item name with format "Progressive Wave Cap (<char>)"
		var isplit = item_name.rsplit("(", false, 1)
		var character_name = item_name.rsplit("(", false, 1)[1].trim_suffix(")")
		if wave_cap_increases_received.has(character_name):
			wave_cap_increases_received[character_name] += 1
		else:
			wave_cap_increases_received[character_name] = 1
		emit_signal("wave_cap_increase_received", character_name)
