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
extends "res://mods-unpacked/RampagingHippy-Archipelago/progress/_base.gd"
class_name ApLootCrateProgress

const LOG_NAME = "RampagingHippy-Archipelago/progress/loot_crates"

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

## Emitted when a crate is picked up to indicate the updated progress to the next check.
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

# Indicates if we can spawn AP loot crates. Determined by current check progress and the
# number of AP loot crates already spawned in the current wave.
var can_spawn_consumable: bool = false

# The index of the last unlocked loot crate group. Determined by the number of wins.
var last_unlocked_group_idx: int = 0

# The number of available loot crate locations based on the number of wins.
var num_unlocked_locations: int = 0

# The index of the last loot crate locations checked across all groups. We don't want to
# use RoomInfo for this because locations can be checked without us finding them (ex.
# release or send_location), and we always want to "find" them in order.
var num_locations_checked: int = 0

var location_idx_to_id: Dictionary
var location_check_status: Dictionary

# The number of AP loot crates currently on the field.
var _num_crates_spawned: int = 0
var _wins_received: int = 0

var _check_progress_data_storage_key: String = ""
var _num_locations_checked_storage_key: String = ""

# The type of loot crate drop to track. Either "common" or "legendary".
var crate_type: String

func _init(ap_client, game_state, crate_type_: String).(ap_client, game_state):
	crate_type = crate_type_
	var _status = _ap_client.connect(
		"data_storage_updated",
		self,
		"_on_session_data_storage_updated"
	)

func notify_crate_spawned():
	## Called by the game extensions when an AP loot crate is spawned in-game.
	_num_crates_spawned += 1
	_update_can_spawn_consumable()

func notify_crate_picked_up():
	## Called by the game extensions when an AP loot crate is picked up in-game.
	_num_crates_spawned -= 1
	_update_check_progress(check_progress + 1)

func total_locations_checked() -> int:
	## The total number of loot crate locations checked, including those found by other
	## games collecting/releasing the location
	var num_found = 0
	for location_id in location_check_status:
		if location_check_status[location_id]:
			num_found += 1
	return num_found

func _update_check_progress(new_value: int):
	if check_progress == new_value:
		# In case we get a data storage update for our last crate pickup.
		return
	check_progress = new_value
	ModLoaderLog.debug("%s check progress updated to %d" % [crate_type, new_value], LOG_NAME)
	emit_signal("check_progress_changed", check_progress, crates_per_check)
	
	if check_progress == crates_per_check:
		# Got enough crates to generate a check
		ModLoaderLog.debug("Got enough crates to make a check", LOG_NAME)
		
		check_progress = 0
		emit_signal("check_progress_changed", check_progress, crates_per_check)
		_update_num_locations_checked(num_locations_checked + 1)

	_ap_client.set_value(
		_check_progress_data_storage_key,
		"replace",
		check_progress,
		0,
		false
	)

func _update_num_locations_checked(new_value: int, send_check: bool=true):
	if num_locations_checked == new_value:
		return

	ModLoaderLog.debug("Num %s locations checked updated to %d" % [crate_type, new_value], LOG_NAME)
	num_locations_checked = new_value
	if send_check:
		var location_id = location_idx_to_id[num_locations_checked]
		_ap_client.check_location(location_id)
	_update_can_spawn_consumable()
	
	_ap_client.set_value(
		_num_locations_checked_storage_key,
		"replace",
		num_locations_checked,
		0,
		false
	)

func _update_can_spawn_consumable():
	var possible_checks = floor((check_progress + _num_crates_spawned) / crates_per_check)
	can_spawn_consumable = num_locations_checked + possible_checks < num_unlocked_locations
	ModLoaderLog.debug(
		"Updating can_spawn_consumable: check_progress=%d, crates_spawned=%d, crates_per_check=%d, num_locations_checked=%d, num_unlocked_locations=%d, can_spawn_consumable=%s" % [
			check_progress,
			_num_crates_spawned,
			crates_per_check,
			num_locations_checked,
			num_unlocked_locations,
			can_spawn_consumable
		],
		LOG_NAME
	)

func on_item_received(item_name: String, _item):
	if item_name == "Run Won":
		_wins_received += 1
		# Don't do anything if we're already in the last group
		if last_unlocked_group_idx < loot_crate_groups.size() - 1:
			var next_group = loot_crate_groups[last_unlocked_group_idx + 1]
			if _wins_received >= next_group.wins_to_unlock:
				last_unlocked_group_idx += 1
				num_unlocked_locations += next_group.num_crates
				_update_can_spawn_consumable()

func on_room_updated(updated_room_info: Dictionary):
	if updated_room_info.has("checked_locations"):
		var new_checked_locations = updated_room_info["checked_locations"]
		for location_id in location_check_status:
			if not location_check_status[location_id]:
				location_check_status[location_id] = location_id in new_checked_locations

func on_connected_to_multiworld():
	_wins_received = 0
	location_check_status = {}
	location_idx_to_id = {}
	total_checks = _ap_client.slot_data["num_%s_crate_locations" % crate_type]
	crates_per_check = _ap_client.slot_data["num_%s_crate_drops_per_check" % crate_type]

	# Find all locations that have already been checked
	for idx in range(1, total_checks + 1):
		var location_name = _build_location_name(idx)
		var location_id = _ap_client.data_package.location_name_to_id[location_name]
		location_idx_to_id[idx] = location_id
		location_check_status[location_id] = location_id in _ap_client.checked_locations

	var loot_crate_groups_info = _ap_client.slot_data["%s_crate_drop_groups" % crate_type]
	loot_crate_groups.clear()
	for group in loot_crate_groups_info:
		loot_crate_groups.append(
			LootCrateGroup.new(
				group["index"],
				group["num_crates"],
				group["wins_to_unlock"]
			)
		)

	# The first loot crate group is always unlocked
	last_unlocked_group_idx = 0
	num_unlocked_locations = loot_crate_groups[0].num_crates

	_check_progress_data_storage_key = "%s_%s_loot_crate_check_progress" % [_ap_client.player, crate_type]
	_num_locations_checked_storage_key = "%s_%s_loot_crate_last_location_checked" % [_ap_client.player, crate_type]

	# Initialize the data storage to track the loot crate check progress
	_ap_client.set_value(
		_check_progress_data_storage_key,
		"default",
		0,
		0,
		true
	)

	# Initialize the data storage to track the last loot crate check found.
	_ap_client.set_value(
		_num_locations_checked_storage_key,
		"default",
		0,
		0,
		true
	)

func on_run_started(_character_ids: Array):
	_num_crates_spawned = 0
	_update_can_spawn_consumable()

func _on_session_data_storage_updated(key: String, new_value, _original_value=null):
	if key == _check_progress_data_storage_key:
		ModLoaderLog.debug("Received check progress DS update: key=%s, new_value=%d" % [key, new_value], LOG_NAME)
		_update_check_progress(new_value)
	elif key == _num_locations_checked_storage_key:
		# Update value but don't send a check, since we have already found this location
		ModLoaderLog.debug("Received num locations DS update: key=%s, new_value=%d" % [key, new_value], LOG_NAME)
		_update_num_locations_checked(new_value, false)

func _build_location_name(index: int) -> String:
	var location_name_prefix: String = ""
	if crate_type == "legendary":
		location_name_prefix = "Legendary "
		
	return "%sLoot Crate %d" % [location_name_prefix, index]
