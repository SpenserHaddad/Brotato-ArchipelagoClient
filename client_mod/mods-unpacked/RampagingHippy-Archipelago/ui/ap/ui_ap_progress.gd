extends PanelContainer

const LOG_NAME = "RampagingHippy-Archipelago/ui_crate_progress"

onready var _contents_container = $MarginContainer/VBoxContainer
onready var _runs_won_label = $MarginContainer/VBoxContainer/RunsWon
onready var _shop_slots_label = $MarginContainer/VBoxContainer/ShopSlots
onready var _common_crate_progress_label = $MarginContainer/VBoxContainer/CommonCrateProgress
onready var _common_crate_wins_needed_label = $MarginContainer/VBoxContainer/CommonCrateWinsNeeded
onready var _legendary_crate_progress_label = $MarginContainer/VBoxContainer/LegendaryCrateProgress
onready var _legendary_crate_wins_needed_label = $MarginContainer/VBoxContainer/LegendaryCrateWinsNeeded
onready var _ap_crate_progress = $MarginContainer/VBoxContainer/ApCrateProgress

var _ap_client

func _ready():
	theme.set_color("font_color", "TooltipLabel", Color(1, 1, 1))

func set_client(ap_client):
	_ap_client = ap_client
	update_all_ui()

func update_all_ui():
	update_runs_won_ui()
	update_shop_slots_ui()
	update_all_crate_progress_ui()
	
func update_runs_won_ui():
	var wins_progress = _ap_client.wins_progress
	_runs_won_label.text = "Runs Won: %d / %d" % [wins_progress.num_wins, wins_progress.wins_for_goal]
	
func update_shop_slots_ui():
	var shop_slots_progress = _ap_client.shop_slots_progress
	_shop_slots_label.text = "Shop Slots: %d" % [_ap_client.shop_slots_progress.num_unlocked_shop_slots]
	
func update_all_crate_progress_ui():
	_update_crate_progress_ui(
		_common_crate_progress_label,
		_common_crate_wins_needed_label,
		_ap_client.common_loot_crate_progress
	)
	_update_crate_progress_ui(
		_legendary_crate_progress_label,
		_legendary_crate_wins_needed_label,
		_ap_client.legendary_loot_crate_progress
	)
	
func _update_crate_progress_ui(progress_text: Label, wins_needed_text: Label, crate_progress):
	var crate_type = crate_progress.crate_type.capitalize()
	var num_checked = crate_progress.total_crate_drop_locations_checked
	var total_checks = crate_progress.total_checks
	var checks_available = 0
	for g in range(crate_progress.num_unlocked_groups):
		checks_available += crate_progress.loot_crate_groups[g].num_crates
	
	# Crate locations checked / Available/ Total
	progress_text.text = "%s Crates: %d / %d / %d" % [crate_type, num_checked, checks_available, total_checks]
	
	var next_group_idx = crate_progress.num_unlocked_groups
	if next_group_idx < crate_progress.loot_crate_groups.size():
		var next_crate_group = crate_progress.loot_crate_groups[next_group_idx]
		var wins_needed = next_crate_group.wins_to_unlock - _ap_client.wins_progress.num_wins
		var win_str = "wins" if wins_needed != 1 else "win"
		wins_needed_text.text = "%d %s needed to unlock next %d %s crates" % [wins_needed, win_str, next_crate_group.num_crates, crate_type]
	else:
		wins_needed_text.text = "All %s crates are available!" % crate_type
