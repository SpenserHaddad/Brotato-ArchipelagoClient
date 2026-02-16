class_name ApMultiWorldProgress
extends PanelContainer

const LOG_NAME = "RampagingHippy-Archipelago/ui_crate_progress"

onready var _contents_container = $MarginContainer/VBoxContainer
onready var _runs_won_label = $MarginContainer/VBoxContainer/RunsWon
onready var _shop_slots_label = $MarginContainer/VBoxContainer/ShopSlots
onready var _common_crate_progress_label = $MarginContainer/VBoxContainer/CommonCrateProgress
onready var _common_crate_wins_needed_label = $MarginContainer/VBoxContainer/CommonCrateWinsNeeded
onready var _legendary_crate_progress_label = $MarginContainer/VBoxContainer/LegendaryCrateProgress
onready var _legendary_crate_wins_needed_label = $MarginContainer/VBoxContainer/LegendaryCrateWinsNeeded

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
	_runs_won_label.text = tr("RHAP_PROGRESS_RUNS_WON").format({amount=wins_progress.num_wins, total=wins_progress.wins_for_goal})
	
func update_shop_slots_ui():
	_shop_slots_label.text = tr("RHAP_PROGRESS_SHOP_SLOTS").format({amount=_ap_client.shop_slots_progress.num_unlocked_shop_slots})
	
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
	var crate_type = tr("RHAP_%s_CRATE_LABEL" % crate_progress.crate_type.to_upper())
	var num_checked = crate_progress.total_locations_checked()
	var checks_available = crate_progress.num_unlocked_locations
	var total_checks = crate_progress.total_checks

	# Crate locations checked / Available/ Total
	progress_text.text = tr("RHAP_PROGRESS_CRATES_COUNT").format({crate_type=crate_type,checked=num_checked, available=checks_available, total=total_checks})
	
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
		wins_needed_text.text = tr("RHAP_PROGRESS_CRATES_WINS_TO_NEXT_GROUP").format({crate_type=crate_type, wins_needed=wins_needed, wins=wins_str, num_crates=next_crate_group.num_crates})
	else:
		wins_needed_text.text = tr("RHAP_PROGRESS_CRATES_ALL_AVAILABLE").format({crate_type=crate_type})
