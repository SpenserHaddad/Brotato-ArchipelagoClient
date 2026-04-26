extends PanelContainer

export (String) var title

onready var _title_label = $VBoxContainer/Title
#onready var _locations_checked_value = $VBoxContainer/LocationsChecked/Value
onready var _locations_checked = $"%LocationsChecked"
onready var _locations_available = $"%LocationsAvailable"
onready var _locations_total = $"%LocationsTotal"
onready var _wins_to_next_group = $"%WinsToNextGroup"

func _ready():
	_title_label.set_text(title)
		
func update_progress(crates_progress, num_wins: int):
	var num_checked = crates_progress.total_locations_checked()
	var checks_available = crates_progress.num_unlocked_locations
	var total_checks = crates_progress.total_checks
	
	_locations_checked.set_value(str(num_checked))
	_locations_available.set_value(str(checks_available))
	_locations_total.set_value(str(total_checks))
	
	var next_group_idx = crates_progress.last_unlocked_group_idx + 1
	if next_group_idx < crates_progress.loot_crate_groups.size():
		var next_crate_group = crates_progress.loot_crate_groups[next_group_idx]
		var wins_needed = next_crate_group.wins_to_unlock - num_wins
		_wins_to_next_group.set_value(str(wins_needed))
	else:
		_wins_to_next_group.set_value(tr("RHAP_PROGRESS_CRATES_ALL_GROUPS_AVAILABLE"))
