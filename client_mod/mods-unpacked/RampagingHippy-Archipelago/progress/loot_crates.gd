extends ApProgressBase
class_name ApLootCrateProgress

class LootCrateGroup:
	var index: int
	var num_crates: int
	var wins_to_unlock: int

	func _init(index_: int, num_crates_: int, wins_to_unlock_: int):
		index = index_
		num_crates = num_crates_
		wins_to_unlock = wins_to_unlock_

signal can_spawn_crate_changed(can_spawn_crate, crate_type)

var total_checks: int
var crates_per_check: int
var loot_crate_groups: Array
var check_progress: int = 0
var group_idx: int = 0
var group_crate_idx: int = 0
var can_spawn_crate: bool = false
var num_unlocked_groups: int = 1
var total_crate_drop_locations_checked: int = 0
var crates_spawned: int = 0
var _wins_received: int = 0

var crate_type: String # Should be either "common" or "legendary"
var game_state

func _init(ap_session, game_state, crate_type_: String).(ap_session):
	game_state = game_state
	crate_type = crate_type_
	var _status = game_state.connect("run_started", self, "_on_run_started")

func notify_crate_spawned():
	crates_spawned += 1
	_update_can_spawn_crate()

func notify_crate_picked_up():
	check_progress += 1
	if check_progress == crates_per_check:
		# Got enough crates to generate a check
		total_crate_drop_locations_checked += 1
		group_crate_idx += 1
		check_progress = 0
		# Send check
		var location_name = "Loot Crate %d" % total_crate_drop_locations_checked
		var location_id = _ap_session.data_package.location_name_to_id[location_name]
		_ap_session.check_location(location_id)

		# Update latest tracked group
		if group_crate_idx > loot_crate_groups[group_idx].num_crates:
			# We've found all crates in this group, increment to the next one.
			group_idx += 1
			group_crate_idx = 0
			_update_can_spawn_crate()

func _update_can_spawn_crate(force_signal=false):
	var new_can_spawn_crate = (
		group_idx <= num_unlocked_groups and
		group_crate_idx <= loot_crate_groups[group_idx].num_crates
	)
	if new_can_spawn_crate != can_spawn_crate or force_signal:
		can_spawn_crate = new_can_spawn_crate
		emit_signal("can_spawn_crate_changed", can_spawn_crate, crate_type)

func _on_run_started(_character_id: String):
	_update_can_spawn_crate(true)

func on_item_received(item_name: String, _item):
	if item_name == "Run Won":
		_wins_received += 1
		# Don't do anything if we're already in the last group
		if num_unlocked_groups < loot_crate_groups.size() - 1:
			var next_group = loot_crate_groups[num_unlocked_groups + 1]
			if _wins_received >= next_group.wins_to_unlock:
				num_unlocked_groups += 1
				_update_can_spawn_crate()

func on_connected_to_multiworld():
	total_checks = _ap_session.slot_data["num_%s_crate_locations" % crate_type]
	crates_per_check = _ap_session.slot_data["num_%s_crate_drops_per_check" % crate_type]
	var loot_crate_groups_info = _ap_session.slot_data["%s_crate_drop_groups" % crate_type]

	for group in loot_crate_groups_info:
		loot_crate_groups.append(
			LootCrateGroup.new(
				group["index"],
				group["num_crates"],
				group["wins_to_unlock"]
			)
		)
