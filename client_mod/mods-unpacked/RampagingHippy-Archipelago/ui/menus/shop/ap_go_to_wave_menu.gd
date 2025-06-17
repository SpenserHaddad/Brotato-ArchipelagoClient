extends HBoxContainer

const BrotatoApConstants = preload("res://mods-unpacked/RampagingHippy-Archipelago/ap/constants.gd")

onready var WaveOptionButton = $WaveOptionButton

onready var _ap_client

# Called when the node enters the scene tree for the first time.
func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client
	var constants = BrotatoApConstants.new()
	
	var min_wave_completed_by_all_chars: int = 0
	var ap_character_info = _ap_client.character_progress.character_info
	
	for i in range(RunData.get_player_count()):
		var player_character_id = RunData.get_player_character(i).my_id
		var player_character = constants.CHARACTER_ID_TO_NAME[player_character_id]
		var max_wave_completed_by_char = ap_character_info[player_character].max_wave_completed
		if max_wave_completed_by_char < min_wave_completed_by_all_chars:
			min_wave_completed_by_all_chars = max_wave_completed_by_char

	for w in range(1, RunData.nb_of_waves + 1):
		var can_select_wave = w <= min_wave_completed_by_all_chars
		WaveOptionButton.add_item(String(w))
		WaveOptionButton.set_item_disabled(w - 1, not can_select_wave)
		

	if min_wave_completed_by_all_chars > 0:
		WaveOptionButton.select(String(min_wave_completed_by_all_chars))
