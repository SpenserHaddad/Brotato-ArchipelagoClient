extends HBoxContainer

const BrotatoApConstants = preload("res://mods-unpacked/RampagingHippy-Archipelago/ap/constants.gd")

signal skip_to_wave_updated(enabled, wave)

onready var _skip_to_wave_button = $SkipToWaveButton
onready var _wave_select_button = $WaveSelectButton
onready var _ap_client

# Called when the node enters the scene tree for the first time.
func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client

	var character_ids = []
	for i in range(RunData.get_player_count()):
		var player_character_id = RunData.get_player_character(i).my_id
		character_ids.append(player_character_id)

	# Set skip_to_wave to the max value, assuming we can't skip unless skip_enabled is set.
	var max_skippable_wave = _ap_client.wave_skip_hook.update_max_skippable_wave(character_ids, true)

	for w in range(1, RunData.nb_of_waves + 1):
		var can_select_wave = w <= max_skippable_wave and w > RunData.current_wave
		_wave_select_button.add_item(String(w))
		_wave_select_button.set_item_disabled(w - 1, not can_select_wave)

	if max_skippable_wave > 0:
		_wave_select_button.select(max_skippable_wave - 1)

	var normal_next_wave = RunData.current_wave + 1

	# Disable the control if there's no future waves to skip to
	if max_skippable_wave <= normal_next_wave:
		_wave_select_button.disabled = true
		_skip_to_wave_button.disabled = true

func _on_SkipToWaveButton_toggled(button_pressed):
	_ap_client.wave_skip_hook.skip_enabled = button_pressed
	emit_signal(
		"skip_to_wave_updated",
		_ap_client.wave_skip_hook.skip_enabled,
		_ap_client.wave_skip_hook.skip_to_wave
	)


func _on_WaveSelectButton_item_selected(index):
	_ap_client.wave_skip_hook.skip_to_wave = index + 1
	emit_signal(
		"skip_to_wave_updated",
		_ap_client.wave_skip_hook.skip_enabled,
		_ap_client.wave_skip_hook.skip_to_wave
	)
