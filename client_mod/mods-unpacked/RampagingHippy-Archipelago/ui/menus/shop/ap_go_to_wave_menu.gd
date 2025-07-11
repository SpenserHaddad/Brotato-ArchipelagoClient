extends HBoxContainer

const BrotatoApConstants = preload("res://mods-unpacked/RampagingHippy-Archipelago/ap/constants.gd")

signal skip_to_wave_toggled(enabled)

onready var _skip_to_wave_button = $SkipToWaveButton
onready var _wave_select_button = $WaveSelectButton
onready var _ap_client
onready var _normal_next_wave

var skip_to_wave = -1

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
		if max_wave_completed_by_char < min_wave_completed_by_all_chars or min_wave_completed_by_all_chars == 0:
			min_wave_completed_by_all_chars = max_wave_completed_by_char

	for w in range(1, RunData.nb_of_waves + 1):
		var can_select_wave = w <= min_wave_completed_by_all_chars and w > RunData.current_wave
		_wave_select_button.add_item(String(w))
		_wave_select_button.set_item_disabled(w - 1, not can_select_wave)
		
	if min_wave_completed_by_all_chars > 0:
		_wave_select_button.select(min_wave_completed_by_all_chars - 1)
	
	_normal_next_wave = RunData.current_wave + 1
		
	# Disable the control if there's no future waves to skip to
	if min_wave_completed_by_all_chars <= _normal_next_wave:
		_wave_select_button.disabled = true
		_skip_to_wave_button.disabled = true

func _on_SkipToWaveButton_toggled(button_pressed):
	if button_pressed:
		skip_to_wave = _wave_select_button.selected + 1
	else:
		skip_to_wave = -1
	emit_signal("skip_to_wave_toggled", button_pressed)


func _on_WaveSelectButton_item_selected(index):
	var skip_enabled = _skip_to_wave_button.pressed
	if skip_enabled:
		skip_to_wave = index + 1
	emit_signal("skip_to_wave_toggled", skip_enabled)
