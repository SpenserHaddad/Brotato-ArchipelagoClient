class_name ApMultiWorldProgress
extends PanelContainer

const LOG_NAME = "RampagingHippy-Archipelago/ap_ui_progress"

onready var _runs_won = $MarginContainer/VBoxContainer/RunsWonNew
onready var _shop_slots = $MarginContainer/VBoxContainer/ShopSlotsNew
onready var _shop_lock_buttons = $MarginContainer/VBoxContainer/ShopLockButtons
onready var _common_crates = $MarginContainer/VBoxContainer/CommonCrates
onready var _legendary_crates = $MarginContainer/VBoxContainer/LegendaryCrates

onready var _ap_client

func _ready():
	theme.set_color("font_color", "TooltipLabel", Color(1, 1, 1))

func set_client(ap_client):
	_ap_client = ap_client
	_ap_client.connect("connection_state_changed", self, "_on_connection_state_changed")

	if _ap_client.connected_to_multiworld():
		update_all_ui()
	else:
		clear_all_ui()

func _on_connection_state_changed(new_state: int, error: int = 0):
	if new_state == BrotatoApClient.ConnectState.CONNECTED_TO_MULTIWORLD:
		update_all_ui()
	else:
		clear_all_ui()

func update_all_ui():
	update_runs_won_ui()
	update_shop_slots_ui()
	update_all_crate_progress_ui()

func clear_all_ui():
	_runs_won.set_value("RHAP_PROGRESS_PLACEHOLDER")
	_shop_slots.set_value("RHAP_PROGRESS_PLACEHOLDER")
	_shop_lock_buttons.set_value("RHAP_PROGRESS_PLACEHOLDER")
	_common_crates.clear_progress()
	_legendary_crates.clear_progress()

func update_runs_won_ui():
	var wins_progress = _ap_client.wins_progress
	var num_wins = wins_progress.num_wins
	var wins_for_goal = wins_progress.wins_for_goal
	_runs_won.set_value("%d / %d" % [wins_progress.num_wins, wins_progress.wins_for_goal])
	
func update_shop_slots_ui():
	_shop_slots.set_value(str(_ap_client.shop_slots_progress.num_unlocked_shop_slots))
	_shop_lock_buttons.set_value(str(_ap_client.shop_lock_buttons_progress.num_unlocked_shop_lock_buttons))
	
func update_all_crate_progress_ui():
	_common_crates.update_progress(_ap_client.common_loot_crate_progress, _ap_client.wins_progress.num_wins)
	_legendary_crates.update_progress(_ap_client.legendary_loot_crate_progress, _ap_client.wins_progress.num_wins)
