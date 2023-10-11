extends "res://ui/menus/run/character_selection.gd"
var _brotato_client

const LOG_NAME = "RampagingHippy-Archipelago/character_selection"

var _unlocked_characters: Array = []

func _ensure_brotato_client():
	# Because Godot calls the base _ready() before this one, and the base
	# ready calls `get_elements_unlocked`, it's possible our override is called
	# before it is ready. So, we can't just init the client in _ready() like normal.
	if _brotato_client != null:
		return
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_brotato_client = mod_node.brotato_client
	for character in _brotato_client.game_data.received_characters:
		if _brotato_client.game_data.received_characters[character]:
			_add_character(character)
	var _status = _brotato_client.connect("character_received", self, "_on_character_received")

func _add_character(character_name: String):
	var character_id = _brotato_client.constants.CHARACTER_NAME_TO_ID[character_name]
	ModLoaderLog.debug("Unlocking character %s" % character_id, LOG_NAME)
	_unlocked_characters.append(character_id)

func _on_character_received(character: String):
	_unlocked_characters.append(character)

func get_elements_unlocked() -> Array:
	ModLoaderLog.debug("Getting unlocked characters", LOG_NAME)
	_ensure_brotato_client()
	if _brotato_client.connected_to_multiworld():
		return _unlocked_characters
	else:
		return .get_elements_unlocked()
