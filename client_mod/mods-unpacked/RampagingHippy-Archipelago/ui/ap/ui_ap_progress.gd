class_name ApMultiWorldProgress
extends PanelContainer

const LOG_NAME = "RampagingHippy-Archipelago/ui_crate_progress"

onready var _runs_won = $MarginContainer/VBoxContainer/RunsWonNew
onready var _shop_slots = $MarginContainer/VBoxContainer/ShopSlotsNew
onready var _shop_lock_buttons = $MarginContainer/VBoxContainer/ShopLockButtons
onready var _common_crates_progress = $MarginContainer/VBoxContainer/CommonCratesProgress
onready var _common_crates_next_group = $MarginContainer/VBoxContainer/CommonCratesNextGroup
onready var _legendary_crates_progress = $MarginContainer/VBoxContainer/LegendaryCratesProgress
onready var _legendary_crates_next_group = $MarginContainer/VBoxContainer/LegendaryCratesNextGroup

var _ap_client

func _ready():
	theme.set_color("font_color", "TooltipLabel", Color(1, 1, 1))

func set_client(ap_client):
	_ap_client = ap_client
	_ap_client.connect("connection_state_changed", self, "_on_connection_state_changed")

	update_all_ui()

func _on_connection_state_changed(new_state: int, error: int = 0):
	if new_state == BrotatoApClient.ConnectState.CONNECTED_TO_MULTIWORLD:
		update_all_ui()

func update_all_ui():
	update_runs_won_ui()
	update_shop_slots_ui()
	update_all_crate_progress_ui()
	
func update_runs_won_ui():
	var wins_progress = _ap_client.wins_progress
	var num_wins = wins_progress.num_wins
	var wins_for_goal = wins_progress.wins_for_goal
	_runs_won.set_value("%d / %d" % [wins_progress.num_wins, wins_progress.wins_for_goal])
	
func update_shop_slots_ui():
	_shop_slots.set_value(str(_ap_client.shop_slots_progress.num_unlocked_shop_slots))
	_shop_lock_buttons.set_value(str(_ap_client.shop_lock_buttons_progress.num_unlocked_shop_lock_buttons))
	
func update_all_crate_progress_ui():
	_update_crate_progress_ui(
		_common_crates_progress,
		_common_crates_next_group,
		_ap_client.common_loot_crate_progress
	)
	_update_crate_progress_ui(
		_legendary_crates_progress,
		_legendary_crates_next_group,
		_ap_client.legendary_loot_crate_progress
	)
	
func _update_crate_progress_ui(progress_control, groups_control, crate_progress):
	var crate_type = tr("RHAP_%s_CRATE_LABEL" % crate_progress.crate_type.to_upper())
	var num_checked = crate_progress.total_locations_checked()
	var checks_available = crate_progress.num_unlocked_locations
	var total_checks = crate_progress.total_checks

	# Crate locations checked / Available/ Total
	progress_control.set_value("%d / %d / %d" % [num_checked, checks_available, total_checks])
	var next_group_idx = crate_progress.last_unlocked_group_idx + 1
	if next_group_idx < crate_progress.loot_crate_groups.size():
		var next_crate_group = crate_progress.loot_crate_groups[next_group_idx]
		var wins_needed = next_crate_group.wins_to_unlock - _ap_client.wins_progress.num_wins
		ModLoaderLog.debug(
			"Updating loot %s crate progress: checked=%d, available=%d, total=%d, wins_needed=%d, wins_to_unlock=%d, num_wins=%d" % [
				crate_type, num_checked, checks_available, total_checks, wins_needed, next_crate_group.wins_to_unlock, _ap_client.wins_progress.num_wins
			],
			LOG_NAME
		)
		var wins_str = tr("RHAP_PROGRESS_WINS_SINGULAR") if wins_needed == 1 else tr("RHAP_PROGRESS_WINS_PLURAL")
		groups_control.set_value(wins_str)
	else:
		groups_control.set_value(tr("RHAP_PROGRESS_CRATES_ALL_AVAILABLE").format({crate_type=crate_type}))
