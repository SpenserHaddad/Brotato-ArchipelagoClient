## Track information about each character for the player slot.
## This includes whether the character is available (we've received their item from the
## MultiWorld), whether they have won their run, and the highest wave the player
## completed with them.
extends "res://mods-unpacked/RampagingHippy-Archipelago/progress/_base.gd"
class_name ApCharacterProgress

const LOG_NAME = "RampagingHippy-Archipelago/progress/characters"

class CharacterProgress:
	var included: bool
	var won_run: bool
	var won_run_location_id: int
	var unlocked: bool = false
	var max_wave_completed: int = 0

	func _init(included_: bool, won_run_: bool, won_run_location_id_: int):
		self.included = included_
		self.won_run = won_run_
		self.won_run_location_id = won_run_location_id_

var character_info: Dictionary

var _character_run_progress_slot_data_key: String
var _included_characters: Array
	
func _init(ap_client, game_state).(ap_client, game_state):
	character_info = {}

func on_item_received(item_name: String, _item):
	if constants.CHARACTER_NAME_TO_ID.has(item_name):
		character_info[item_name].unlocked = true
		
func on_room_updated(updated_room_info: Dictionary):
	# Check if any of the won run locations for characters we haven't won with yet have
	# been checked. This typically will occur when we won a run and got the
	# confirmation, but it can also happen when the location was collected, or this is
	# a co-op slot, so we can't just check game_state.
	if updated_room_info.has("checked_locations"):
		var new_locations = updated_room_info["checked_locations"]
		for character in character_info:
			var char_info = character_info[character]
			if not char_info.won_run and char_info.won_run_location_id in new_locations:
				char_info.won_run = true

func on_connected_to_multiworld():
	var _default_char_run_progress: Dictionary = {}
	character_info.clear()
	
	if _ap_client.slot_data.has("characters"):
		_included_characters = _ap_client.slot_data["characters"]
		ModLoaderLog.debug("Game has characters: %s" % ", ".join(_included_characters), LOG_NAME)
	else:
		# Legacy mode, just use all characters
		ModLoaderLog.debug("Slot data does not have 'characters' key, defaulting to all characters", LOG_NAME)
		_included_characters = []

	for character in constants.CHARACTER_NAME_TO_ID:
		# We'll determine if characters are unlocked when the item is received, 
		# just check if they won or not here. (TODO: simul-play?)
		var character_won_loc_name = constants.RUN_COMPLETE_LOCATION_TEMPLATE.format({"char": character})
		var character_won_loc_id = _ap_client.data_package.location_name_to_id[character_won_loc_name]
		var character_won = character_won_loc_id in _ap_client.checked_locations
		var character_included = character in _included_characters
		character_info[character] = CharacterProgress.new(character_included, character_won, character_won_loc_id)
		_default_char_run_progress[character] = {"max_wave_completed": 0}

	_character_run_progress_slot_data_key = "%s_character_run_progress" % _ap_client.player
	_ap_client.set_value(
		_character_run_progress_slot_data_key,
		"default",
		{},
		_default_char_run_progress,
		true
	)
	_ap_client.set_notify([_character_run_progress_slot_data_key])

func on_wave_finished(wave_number: int, character_ids: Array, _is_run_lost: bool, _is_run_won: bool):
	# Update the max wave completed for each character currently in play
	if wave_number > 20:
		return

	var updated_run_progress = {}
	for character_id in character_ids:
		var character = constants.CHARACTER_ID_TO_NAME[character_id]
		if character in updated_run_progress or character_info[character].max_wave_completed > wave_number:
			# The former can happen if multiple players pick the same character in co-op.
			continue
			
		updated_run_progress[character] = {"max_wave_completed": wave_number}

	# We'll update the local character info when we get the SetReply
	_ap_client.set_value(
		_character_run_progress_slot_data_key,
		"update",
		updated_run_progress,
		null,
		true
	)

func on_data_storage_updated(key: String, new_value, _original_value = null):
	if key == _character_run_progress_slot_data_key:
		for updated_character in new_value:
			character_info[updated_character].max_wave_completed = new_value[updated_character]["max_wave_completed"]
