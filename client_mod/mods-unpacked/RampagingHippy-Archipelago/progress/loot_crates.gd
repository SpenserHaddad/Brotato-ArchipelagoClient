## Tracks loot crate checks found by the player and notifies the multiworld.
##
## This class is generic for both common and legendary crates, but only tracks one at a
## time. Which is tracked is determined by the `crate_type` argument/field.
##
## Counts the number of loot crates picked up by the player. When the player finds
## enough to make a check, this sends a CheckLocation command via the AP client for the
## corresponding loot crate.
##
## Loot crate drops are also intended to be gated by the player won enough runs with
## different characters, so the checks aren't all in sphere 0. If the next check the
## player would find isn't supposed to be accesible yet, this class will tell the game
## to start dropping normal loot crates instead. When the checks are accessible again,
## we switch back to AP loot crates.
##
## To determine when to switch, this class keeps track of the number of wins, the number
## of loot crate drop locations checked, and the number of loot crate drops on the
## field, if in a run. If the number of crates dropped plus the number of locations
## checks is higher than the number available, we switch the type of crate to drop.
##
## We'll also tell the game to drop vanilla loot crates again when all locations are
## checked.
extends ApProgressBase
class_name ApLootCrateProgress

## Information about a "group" of loot crate checks
##
## We unlock loot crates in groups based on the total number of checks and wins
## required, which is determined at generation time and stored as slot_data. This is
## just local storage for the slot data for easy access.
class LootCrateGroup:
	var index: int
	# The number of loot crate checks in this group
	var num_crates: int
	# The number of wins needed to make the checks in this group accessible.
	var wins_to_unlock: int

	func _init(index_: int, num_crates_: int, wins_to_unlock_: int):
		index = index_
		num_crates = num_crates_
		wins_to_unlock = wins_to_unlock_

## Emitted when we have to change whether to drop AP loot crates or vanilla loot crates.
## This is also always emitted at the start of a run to tell the game which type of
## crate to drop.
signal can_spawn_crate_changed(can_spawn_crate, crate_type)
signal check_progress_changed(progress, total)

# The total number of loot crate checks available.
var total_checks: int

# The number of loot crates that need to be picked up to count as a check.
var crates_per_check: int

# Information about each "group" of loot crates gated behind a certain number of wins.
var loot_crate_groups: Array

# The number of loot crates picked up for the current check. When this equals 
# crates_per_check, the next location will be checked.
var check_progress: int = 0

# The current loot crate group we're finding checks for.
var group_idx: int = 0

# The current loot crate check in the group we're progressing towards.
var group_crate_idx: int = 0

# Indicates if we can spawn AP loot crates. Determined by current check progress and the
# number of AP loot crates already spawned in the current wave.
var can_spawn_crate: bool = false

# The total number of unlocked loot crate groups. Determined by the number of wins
# received.
var num_unlocked_groups: int = 1

# The total number of loot crate locations checked across all groups
var total_crate_drop_locations_checked: int = 0

# The number of AP loot crates currently on the field.
var crates_spawned: int = 0
var _wins_received: int = 0

# The type of loot crate drop to track. Either "common" or "legendary".
var crate_type: String

func _init(ap_client, game_state, crate_type_: String).(ap_client, game_state):
	crate_type = crate_type_

func notify_crate_spawned():
	## Called by the game extensions when an AP loot crate is spawned in-game.
	crates_spawned += 1
	_update_can_spawn_crate()

func notify_crate_picked_up():
	## Called by the game extensions when an AP loot crate is picked up in-game.
	check_progress += 1
	emit_signal("check_progress_changed", check_progress, crates_per_check)	
	if check_progress == crates_per_check:
		# Got enough crates to generate a check
		total_crate_drop_locations_checked += 1
		group_crate_idx += 1
		check_progress = 0
		# Send check
		var location_name = "Loot Crate %d" % total_crate_drop_locations_checked
		var location_id = _ap_client.data_package.location_name_to_id[location_name]
		_ap_client.check_location(location_id)

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
	total_checks = _ap_client.slot_data["num_%s_crate_locations" % crate_type]
	crates_per_check = _ap_client.slot_data["num_%s_crate_drops_per_check" % crate_type]
	var loot_crate_groups_info = _ap_client.slot_data["%s_crate_drop_groups" % crate_type]

	for group in loot_crate_groups_info:
		loot_crate_groups.append(
			LootCrateGroup.new(
				group["index"],
				group["num_crates"],
				group["wins_to_unlock"]
			)
		)

func on_run_started(_character_id: String):
	_update_can_spawn_crate(true)
