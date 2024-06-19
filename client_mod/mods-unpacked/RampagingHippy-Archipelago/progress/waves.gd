extends ApProgressBase
class_name ApWavesProgress

var waves_with_checks: PoolIntArray

func _init(ap_session, game_state).(ap_session, game_state):
	var _status = _game_state.connect("wave_finished", self, "_on_wave_finished")

func on_connected_to_multiworld():
	waves_with_checks = PoolIntArray(_ap_session.slot_data["waves_with_checks"])

func _on_wave_finished(wave_number: int, character_id: String):
	if waves_with_checks.has(wave_number):
		# TODO: check if location was checked already
		var character_name = constants.CHARACTER_ID_TO_NAME[character_id]
		var location_name = "Wave %d Completed (%s)" % [wave_number, character_name]
		var location_id = _ap_session.data_package.location_name_to_id[location_name]
		if _ap_session.missing_locations.has(location_id):
			_ap_session.check_location(location_id)