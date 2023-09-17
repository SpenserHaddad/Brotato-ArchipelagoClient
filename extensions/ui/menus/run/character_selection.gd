extends "res://ui/menus/run/character_selection.gd"
onready var _brotato_client: BrotatoApAdapter

var _unlocked_characters: Array = []

func _ready()->void :
	ModLoaderLog.debug("Char-gen ready", ArchipelagoModBase.MOD_NAME)
	_ensure_brotato_client()
#	._ready()

func _ensure_brotato_client():
	# Because Godot calls the base _ready() before this one, and the base
	# ready calls `get_elements_unlocked`, it's possible our override is called
	# before it is ready. So, we can't just init the client in _ready() like normal.
	if _brotato_client != null:
		return
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_brotato_client = mod_node.brotato_client
	ModLoaderLog.debug("Got AP client %s" % _brotato_client, ArchipelagoModBase.MOD_NAME)
	for unlocked_char in _brotato_client.game_data.received_characters:
		_add_character(unlocked_char)
	var _status = _brotato_client.connect("character_received", self, "_on_character_received")

func _add_character(character_name: String):
	var character_id = "character_" + character_name.replace(" ", "_").to_lower()
	ModLoaderLog.debug("Unlocking character %s" % character_id, ArchipelagoModBase.MOD_NAME)
	_unlocked_characters.append(character_id)

func _on_character_received(character: String):
	_unlocked_characters.append(character)

func get_elements_unlocked() -> Array:
	_ensure_brotato_client()
	ModLoaderLog.debug("Getting unlocked characters", ArchipelagoModBase.MOD_NAME)
	if _brotato_client.connected_to_multiworld():
		return _unlocked_characters
	else:
		return .get_elements_unlocked()
