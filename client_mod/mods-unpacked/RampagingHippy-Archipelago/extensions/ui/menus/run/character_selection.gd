extends "res://ui/menus/run/character_selection.gd"
var _ap_client

const LOG_NAME = "RampagingHippy-Archipelago/character_selection"

var _unlocked_characters: Array = []

func _ensure_ap_client():
	# Because Godot calls the base _ready() before this one, and the base
	# ready calls `get_elements_unlocked`, it's possible our override is called
	# before it is ready. So, we can't just init the client in _ready() like normal.
	if _ap_client != null:
		return
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client
	for character in _ap_client.game_state.character_progress:
		if _ap_client.game_state.character_progress[character].unlocked:
			_add_character(character)
	var _status = _ap_client.connect("character_received", self, "_on_character_received")

func _add_character(character_name: String):
	var character_id = _ap_client.constants.CHARACTER_NAME_TO_ID[character_name]
	_unlocked_characters.append(character_id)

func _on_character_received(character: String):
	_unlocked_characters.append(character)

func get_elements_unlocked() -> Array:
	ModLoaderLog.debug("Getting unlocked characters", LOG_NAME)
	_ensure_ap_client()
	if _ap_client.connected_to_multiworld():
		var character_str = ", ".join(_unlocked_characters)
		ModLoaderLog.debug("Unlocking characters %s" % character_str, LOG_NAME)
		return _unlocked_characters
	else:
		ModLoaderLog.debug("Returning default characters", LOG_NAME)
		return .get_elements_unlocked()
