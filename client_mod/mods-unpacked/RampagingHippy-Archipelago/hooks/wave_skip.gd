class_name ApWaveSkipHook
extends Node

const BrotatoApConstants = preload("res://mods-unpacked/RampagingHippy-Archipelago/ap/constants.gd")

const LOG_NAME = "RampagingHippy-Archipelago/hooks/hack_shop_setup"

var skip_enabled: bool = false
var skip_to_wave: int = -1
var max_skippable_wave: int = -1

onready var _ap_client
onready var _constants

func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client
	_ap_client.game_state.connect("wave_started", self, "_on_wave_started")

func update_max_skippable_wave(character_ids: Array, set_skip_to_wave: bool = true) -> int:
	# Set the highest wave that can be skipped to,  for the given characters.
	# Checks the highest wave reached by each character, and sets max_skippable_wave to
	# the lowest value. Returns the value for convenience.
	# #
	# # If set_skip_to_wave is true, also sets skip_to_wave to the new value.
	var constants = BrotatoApConstants.new()
	var min_wave_completed_by_all_chars: int = 0
	var ap_character_info = _ap_client.character_progress.character_info
	for character_id in character_ids:
		var character_name = constants.CHARACTER_ID_TO_NAME[character_id]
		var max_wave_completed_by_char = ap_character_info[character_name].max_wave_completed
		if max_wave_completed_by_char < min_wave_completed_by_all_chars or min_wave_completed_by_all_chars == 0:
			min_wave_completed_by_all_chars = max_wave_completed_by_char

	max_skippable_wave = min_wave_completed_by_all_chars
	if set_skip_to_wave:
		skip_to_wave = min_wave_completed_by_all_chars
	return min_wave_completed_by_all_chars

func _on_wave_started(_wave_number, _character_ids):
	# Clear the skip flag after leaving a shop or starting a run.
	ModLoaderLog.debug("Clearing skip flag", LOG_NAME)
	skip_enabled = false
