class_name ApMultiWorldProgress
extends PanelContainer

const BrotatoApClient = preload("res://mods-unpacked/RampagingHippy-Archipelago/ap/brotato_ap_client.gd")

const LOG_NAME = "RampagingHippy-Archipelago/ap_ui_progress"

onready var _runs_won = $MarginContainer/VBoxContainer/RunsWonNew
onready var _wave_cap_increases = $MarginContainer/VBoxContainer/WaveCapIncreases
onready var _wave_cap = $MarginContainer/VBoxContainer/WaveCap
onready var _shop_slots = $MarginContainer/VBoxContainer/ShopSlotsNew
onready var _shop_lock_buttons = $MarginContainer/VBoxContainer/ShopLockButtons
onready var _common_crates = $MarginContainer/VBoxContainer/CommonCrates
onready var _legendary_crates = $MarginContainer/VBoxContainer/LegendaryCrates

onready var _ap_client

func _ready():
	theme.set_color("font_color", "TooltipLabel", Color(1, 1, 1))

func set_client(ap_client):
	_ap_client = ap_client
	_ap_client.connect("connection_state_changed", self , "_on_connection_state_changed")
	_ap_client.wins_progress.connect("win_received", self , "_on_win_received")
	_ap_client.waves_progress.connect("wave_cap_increase_received", self, "_on_wave_cap_increase_received")

	if _ap_client.connected_to_multiworld():
		update_all_ui()
	else:
		clear_all_ui()

func _on_connection_state_changed(new_state: int, _error: int = 0):
	if new_state == BrotatoApClient.ConnectState.CONNECTED_TO_MULTIWORLD:
		update_all_ui()
	else:
		clear_all_ui()

func _on_win_received(_new_count: int):
	update_runs_won_ui()

func _on_wave_cap_increase_received():
	update_wave_cap_ui()

func update_all_ui():
	update_runs_won_ui()
	update_wave_cap_ui()
	update_shop_slots_ui()
	update_all_crate_progress_ui()

func clear_all_ui():
	_runs_won.set_value("RHAP_PROGRESS_PLACEHOLDER")
	_wave_cap.set_value("RHAP_PROGRESS_PLACEHOLDER")
	_shop_slots.set_value("RHAP_PROGRESS_PLACEHOLDER")
	_shop_lock_buttons.set_value("RHAP_PROGRESS_PLACEHOLDER")
	_common_crates.clear_progress()
	_legendary_crates.clear_progress()

func update_runs_won_ui():
	var wins_progress = _ap_client.wins_progress
	_runs_won.set_value("%d / %d" % [wins_progress.num_wins, wins_progress.wins_for_goal])

func update_wave_cap_ui():
	var wave_cap = _ap_client.waves_progress.get_wave_cap()
	_wave_cap.set_value(str(wave_cap))
	_wave_cap_increases.set_value("%d / %d" % [
		_ap_client.waves_progress.wave_cap_increases_received,
		_ap_client.waves_progress.total_wave_cap_increases
	])

func update_shop_slots_ui():
	_shop_slots.set_value(str(_ap_client.shop_slots_progress.num_unlocked_shop_slots))
	_shop_lock_buttons.set_value(str(_ap_client.shop_lock_buttons_progress.num_unlocked_shop_lock_buttons))

func update_all_crate_progress_ui():
	_common_crates.update_progress(_ap_client.common_loot_crate_progress, _ap_client.wins_progress.num_wins)
	_legendary_crates.update_progress(_ap_client.legendary_loot_crate_progress, _ap_client.wins_progress.num_wins)
