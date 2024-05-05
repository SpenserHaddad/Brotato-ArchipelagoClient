# Contains information about the game state corresponding to Archipelago's view of it.
# This is a combination of a local copy of any AP options (so we don't need to
# constantly ping the server), and some local trackers for data the mod/client cares
# about, but the server does not.
extends Object
class_name ApGameState

const LOG_NAME = "RampagingHippy-Archipelago/game_state"

class ApCharacterProgress:
	var unlocked: bool = false
	var won_run: bool = false
	# Dictionary of "{ wave_number (int) : wave_completed (bool) } "Indicates whether
	# the player has completed the waves which count as checks with the character. The
	# exact number of waves depends on game settings.
	var reached_check_wave: Dictionary = {}

const _run_state_namespace = preload ("./run_state.gd")
var _constants = preload ("../singletons/constants.gd").new()

# User-defined options from the randomizer. These are retrieved from the slot data on
# the server after connecting. The number of items to drop as consumables in a run.
var total_consumable_drops: int
var total_legendary_consumable_drops: int
var num_starting_shop_slots: int
var num_wins_needed: int
var num_common_crate_drops_per_check: int
var num_legendary_crate_drops_per_check: int
# Correspond to BrotatoLootCrateGroup in the apworld. 
# Has keys"index", "num_crates" and "wins_to_unlock".
var common_crate_drop_groups: Dictionary
var legendary_crate_drop_groups: Dictionary

# Cumulative values updated as the player receives items and gets checks.
var goal_completed: bool = false
var num_wins: int = 0
var gold_received_from_multiworld: int = 0
var gold_given_to_player: int = 0
var xp_received_from_multiworld: int = 0
var xp_given_to_player: int = 0
var num_received_shop_slots: int = 0
var character_progress: Dictionary = {} # Dictionary of { character_name: ApCharacterProgress }
var num_consumables_picked_up: int = 0
var num_legendary_consumables_picked_up: int = 0
var received_items_by_tier: Dictionary = {
	Tier.COMMON: 0,
	Tier.UNCOMMON: 0,
	Tier.RARE: 0,
	Tier.LEGENDARY: 0
}
var received_upgrades_by_tier: Dictionary = {
	Tier.COMMON: 0,
	Tier.UNCOMMON: 0,
	Tier.RARE: 0,
	Tier.LEGENDARY: 0
}

# Data to track when in a run (i.e. actually playing the game).
var run_active: bool = false
var run_state

func _init(
	num_wins_needed_: int,
	total_consumable_drops_: int,
	total_legendary_consumable_drops_: int,
	num_starting_shop_slots_: int,
	waves_with_checks: Array,
	num_common_crate_drops_per_check_: int,
	num_legendary_crate_drops_per_check_: int,
	common_crate_drop_groups_: Dictionary,
	legendary_crate_drop_groups_: Dictionary
):
	num_wins_needed = num_wins_needed_
	total_consumable_drops = total_consumable_drops_
	total_legendary_consumable_drops = total_legendary_consumable_drops_
	num_starting_shop_slots = num_starting_shop_slots_
	num_common_crate_drops_per_check = num_common_crate_drops_per_check_
	num_legendary_crate_drops_per_check = num_legendary_crate_drops_per_check_
	common_crate_drop_groups = common_crate_drop_groups_
	legendary_crate_drop_groups = legendary_crate_drop_groups_
	for character in _constants.CHARACTER_NAME_TO_ID:
		character_progress[character] = ApCharacterProgress.new()
		for wave in waves_with_checks:
			character_progress[character].reached_check_wave[int(wave)] = false

# Helpers to get combined values
func num_shop_slots() -> int:
	return num_starting_shop_slots + num_received_shop_slots

func num_existing_consumables() -> int:
	return num_consumables_picked_up + run_state.ap_consumables_not_picked_up

func num_existing_legendary_consumables() -> int:
		return num_legendary_consumables_picked_up + run_state.ap_legendary_consumables_not_picked_up

# Helpers to update state when in-game events happen
func consumable_spawned():
	run_state.ap_consumables_not_picked_up += 1

func legendary_consumable_spawned():
	run_state.ap_legendary_consumables_not_picked_up += 1

func consumable_picked_up():
	num_consumables_picked_up += 1
	run_state.ap_consumables_not_picked_up -= 1

func legendary_consumable_picked_up():
	num_legendary_consumables_picked_up += 1
	run_state.ap_legendary_consumables_not_picked_up -= 1

func run_started():
	run_active = true
	run_state = _run_state_namespace.new()

func run_finished():
	run_active = false

func wave_started():
	run_state.wave_started()
