extends PanelContainer

export (String) var title

onready var _title_label = $VBoxContainer/Title
onready var _locations_checked_value = $VBoxContainer/LocationsChecked/Value
onready var _locations_available_value = $VBoxContainer/LocationsAvailable/Value
onready var _locations_total_value = $VBoxContainer/LocationsTotal/Value
onready var _wins_to_next_group_value = $VBoxContainer/WinsToNextGroup/Value

func _ready():
	_title_label.set_text(title)
		
func update_progress(crates_progress, num_wins: int):
	var num_checked = crates_progress.total_locations_checked()
	var checks_available = crates_progress.num_unlocked_locations
	var total_checks = crates_progress.total_checks
	
	_locations_checked_value.set_text(str(num_checked))
	_locations_available_value.set_text(str(checks_available))
	_locations_total_value.set_text(str(total_checks))
	
	var next_group_idx = crates_progress.last_unlocked_group_idx + 1
	if next_group_idx < crates_progress.loot_crate_groups.size():
		var next_crate_group = crates_progress.loot_crate_groups[next_group_idx]
		var wins_needed = next_crate_group.wins_to_unlock - num_wins
		_wins_to_next_group_value.set_text(str(wins_needed))
	else:
		_wins_to_next_group_value.set_text(tr("RHAP_PROGRESS_CRATES_ALL_GROUPS_AVAILABLE"))
