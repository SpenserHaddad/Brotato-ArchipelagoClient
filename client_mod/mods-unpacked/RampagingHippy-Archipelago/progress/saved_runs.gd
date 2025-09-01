## Track in progress runs for different characters.
##
## A run is saved for each character in the AP server's data storage whenever the game 
## would save the run to disk. This handles sending and receiving saves from the server,
## while the game extensions handle saving and loading the data.
##
## Co-op runs are not saved for simplicity, since we expect that most players won't care
## about resuming them. There shouldn't be anything technical preventing this as a
## future update, however.
##
## Character runs are saved as a dictionary in data storage, where the key is the character ID
## and the value is a dictionary of the following:
##	- decompressed_size (int): The size of "data_b64" when decoded and decompressed, in bytes. 
##	   Needed to call PoolByteArray.decompress.
##	- compression (int): The compression format used to compress the data. Is one of
##	   File.CompressionMode, currently should only ever be COMPRESSION_ZSTD (2).
##	- data_b64 (String): The actual save data, compressed using the compression indicated by
##	   "compression" then base64 encoded.
##
## When decompressed, "data_b64" becomes another dictionary containing:
##	- game_state (Dictionary): The Brotato save game data. Matches what would be saved to file
##	    normally.
##	- ap_state (Dictionary): AP-specific save data, such as how many items/upgrades were received.
##
## Note that older versions of the mod did not use compression, and instead used the data in
## "data_b64" as the value in data storage. We check for this case for backwards compatibility, but
## eventually we should be able to remove support for this when no more slots use the old format.

extends "res://mods-unpacked/RampagingHippy-Archipelago/progress/_base.gd"
class_name ApSavedRunsProgress

const LOG_NAME = "RampagingHippy-Archipelago/progress/saved_runs"
const _DEBUG_SAVE_NAME = "user://ap_debug_save_game"

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
	if not _saved_runs.has(character):
		ModLoaderLog.info("No saved run for %s" % character, LOG_NAME)
		return {}
	
	var saved_run_raw = _saved_runs[character]
	if saved_run_raw.has("data_b64"):
		# Using new compressed format, convert and decompress
		ModLoaderLog.info("Found compressed saved run for %s" % character, LOG_NAME)
		var saved_run_bytes: PoolByteArray = Marshalls.base64_to_raw(saved_run_raw["data_b64"])
		var compression_mode = saved_run_raw["compression"]
		var decompressed_size = saved_run_raw["decompressed_size"]
		var saved_run_decompressed = saved_run_bytes.decompress(decompressed_size, compression_mode)
		var saved_run_str = saved_run_decompressed.get_string_from_utf8()
		var parse_result = JSON.parse(saved_run_str)
		if parse_result.error:
			ModLoaderLog.error(
				"Failed to parse saved character run: error=%s, error_line=%d, error_string=%s" % [
					parse_result.error,
					parse_result.error_line,
					parse_result.error_string
				],
				LOG_NAME
			)
		return parse_result.result
	else:
		# Old uncompressed json format, just return
		ModLoaderLog.info("Found uncompressed saved run for %s" % character, LOG_NAME)
		return saved_run_raw


func get_last_played_char():
	return _last_played_char

func get_last_saved_run():
	return get_saved_run(_last_played_char)

func save_character_run(character: String, game_state: Dictionary, ap_state: Dictionary):
	var combined_save_data = {"game_state": game_state, "ap_state": ap_state}
	var combined_save_data_bytes = JSON.print(combined_save_data).to_utf8()

	var decompressed_data_size = combined_save_data_bytes.size()
	var save_data_compressed = combined_save_data_bytes.compress(File.COMPRESSION_ZSTD)
	var save_data_b64 = Marshalls.raw_to_base64(save_data_compressed)
	var save_info = {
		"compression": File.COMPRESSION_ZSTD,
		"data_b64": save_data_b64,
		"decompressed_size": decompressed_data_size
	}

	_ap_client.set_value(_saved_runs_data_storage_key, "update", {character: save_info})
	_ap_client.set_value(_last_played_char_data_storage_key, "replace", character)

func on_data_storage_updated(key: String, new_value, _original_value = null):
	if key == _saved_runs_data_storage_key:
		ModLoaderLog.info("Received updated saved runs from DS key: %s" % _saved_runs_data_storage_key, LOG_NAME)
		_saved_runs = new_value
	elif key == _last_played_char_data_storage_key:
		ModLoaderLog.info("Received updated last played character, %s, from DS key: %s" % [new_value, _last_played_char_data_storage_key], LOG_NAME)
		_last_played_char = new_value
