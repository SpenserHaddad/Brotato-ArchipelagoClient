## Track which characters have been unlocked for the player slot.
extends "res://mods-unpacked/RampagingHippy-Archipelago/progress/_base.gd"
class_name ApCharacterProgress

class CharacterProgress:
	var unlocked: bool = false
	var won_run: bool = false
	var won_run_location_id: int = -1

var character_info: Dictionary
	
func _init(ap_client, game_state).(ap_client, game_state):
	character_info = {}
	for character in constants.CHARACTER_NAME_TO_ID:
		character_info[character] = CharacterProgress.new()
	
func on_item_received(item_name: String, _item):
	if constants.CHARACTER_NAME_TO_ID.has(item_name):
		character_info[item_name].unlocked = true
		
func on_room_updated(updated_room_info: Dictionary):
	# Check if any of the won run locations for characters we haven't won with yet have
	# been checked. This typicallly will occur when we won a run and got the
	# confirmation, but it can also happen when the location was collected, or this is
	# a co-op slot, so we can't just check game_state.
	if updated_room_info.has("checked_locations"):
		var new_locations = updated_room_info["checked_locations"]
		for character in character_info:
			var char_info = character_info[character]
			if not char_info.won_run and char_info.won_run_location_id in new_locations:
				char_info.won_run = true

func on_connected_to_multiworld():
	for character in constants.CHARACTER_NAME_TO_ID:
		# We'll determine if characters are unlocked when the item is received, 
		# just check if they won or not here. (TODO: simul-play?)
		var character_won_loc_name = constants.RUN_COMPLETE_LOCATION_TEMPLATE.format({"char": character})
		var character_won_loc_id = _ap_client.data_package.location_name_to_id[character_won_loc_name]
		var character_won = character_won_loc_id in _ap_client.checked_locations
		character_info[character].won_run = character_won
		character_info[character].won_run_location_id = character_won_loc_id
		# Clear unlocked flag. We'll unlock characters with on_item_received
		character_info[character].unlocked = false
