extends "res://ui/menus/run/character_selection.gd"

const LOG_NAME = "RampagingHippy-Archipelago/character_selection"
const BrotatoApConstants = preload ("res://mods-unpacked/RampagingHippy-Archipelago/ap/constants.gd")
var _ap_client
var _constants
var _unlocked_characters: Array = []
var _progress_panel

onready var _description_container: HBoxContainer = $MarginContainer/VBoxContainer/DescriptionContainer
var _ui_crate_progress

func _ready():
	# The CharacterSelection scene is subclassed by the WeaponSelection and
	# DifficultySelection classes, but we only want to extend the character selection
	# menu.
	if is_char_screen():
		_ensure_ap_client()
		_add_ap_progress_ui()

func _ensure_ap_client():
	# Because Godot calls the base _ready() before this one, and the base ready calls
	# `get_elements_unlocked`, it's possible our override is called before it is ready.
	# So, we can't just init the client in _ready() like normal.
	if _ap_client != null:
		return
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client
	_constants = BrotatoApConstants.new()
	if _ap_client.connected_to_multiworld():
		var character_info = _ap_client.character_progress.character_info
		for character in character_info:
			if character_info[character].unlocked:
				_add_character(character)
		# var _status = _ap_client.character_progress.connect("character_received", self, "_on_character_received")
		_inventory.init_char_select_inventory(_ap_client)

func _add_character(character_name: String):
	var character_id = _constants.CHARACTER_NAME_TO_ID[character_name]
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

func _add_ap_progress_ui():
	if _ap_client.connected_to_multiworld():
		ModLoaderMod.append_node_in_scene(
			self,
			"ApProgress",
			_description_container.get_path(),
			"res://mods-unpacked/RampagingHippy-Archipelago/ui/ap/ui_ap_progress.tscn"
		)
		_progress_panel = _description_container.get_child(3)
		_progress_panel.set_client(_ap_client)
