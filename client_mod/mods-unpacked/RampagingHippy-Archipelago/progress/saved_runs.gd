## Track in progress runs for different characters.
##
## A run is saved for each character in the AP server's data storage whenever the game 
## would save the run to disk. This handles sending and receiving saves from the server,
## while the game extensions handle saving and loading the data.
##
## Co-op runs are not saved for simplicity, since we expect that most players won't care
## about resuming them. There shouldn't be anything technical preventing this as a
## future update, however.

extends "res://mods-unpacked/RampagingHippy-Archipelago/progress/_base.gd"
class_name ApSavedRunsProgress

const LOG_NAME = "RampagingHippy-Archipelago/progress/saved_runs"

# Enable enemy XP (vanilla behavior) until we're connected to a multiworld.
var _saved_runs_data_storage_key: String = ""
var _last_played_char_data_storage_key: String = ""

var _saved_runs: Dictionary = {}
var _last_played_char: String = ""

func _init(ap_client, game_state).(ap_client, game_state):
	pass

func on_connected_to_multiworld():
	# Check the slot data to see if enemies should give XP. Legacy behavior is
	# to just set the value to true.
	_saved_runs_data_storage_key = "%s_saved_runs" % _ap_client.player
	_last_played_char_data_storage_key = "%s_last_played_character" % _ap_client.player
	_ap_client.set_value(_saved_runs_data_storage_key, "default", {}, {}, true)
	_ap_client.set_value(_last_played_char_data_storage_key, "default", "", "", true)
	_ap_client.set_notify([_saved_runs_data_storage_key, _last_played_char_data_storage_key])

func get_saved_run(character: String) -> Dictionary:
	return _saved_runs.get(character, {})

func get_last_played_char():
	return _last_played_char

func get_last_saved_run():
	return _saved_runs.get(_last_played_char, {})

func save_character_run(character: String, game_state: Dictionary, ap_state: Dictionary):
	var combined_save_data = {"game_state": game_state, "ap_state": ap_state}
	_saved_runs[character] = combined_save_data
	_ap_client.set_value(_saved_runs_data_storage_key, "update", {character: combined_save_data})
	_ap_client.set_value(_last_played_char_data_storage_key, "replace", character)

func on_data_storage_updated(key: String, new_value, _original_value = null):
	if key == _saved_runs_data_storage_key:
		ModLoaderLog.info("Received updated saved runs", LOG_NAME)
		_saved_runs = new_value
	elif key == _last_played_char_data_storage_key:
		ModLoaderLog.info("Received updated last played character: %s" % new_value, LOG_NAME)
		_last_played_char = new_value
