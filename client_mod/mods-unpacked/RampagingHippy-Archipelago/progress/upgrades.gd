## Track the number of upgrades received from items, and give them to the player.
##
## Upgrades in this case refers to the stat bonuses received when levelling up.
##
## Listen to the client for upgrades received as Archipelago items, then give them to
## the player immediately if they're in a run, or as soon as they start a new run.
##
## Upgrades are given to the player every run, so we track the total amount of items and
## give them all to the player every time they start a run.
extends "res://mods-unpacked/RampagingHippy-Archipelago/progress/_base.gd"
class_name ApUpgradesProgress

signal upgrade_received(upgrade_tier)

# The number of upgrades processed in the current run. This is set at the start of each
# run to keep track of how many upgrades the player has received from items so far so we
# can set the level of each item correctly.
var processed_upgrades_by_tier: Dictionary

var received_upgrades_by_tier: Dictionary = {
	Tier.COMMON: 0,
	Tier.UNCOMMON: 0,
	Tier.RARE: 0,
	Tier.LEGENDARY: 0
}

func _init(ap_client, game_state).(ap_client, game_state):
	# Need this for Godot to pass through to the base class
	pass

func process_ap_upgrade(upgrade_tier: int):
	# Mark the upgrade as processed so we don't try to give again this run.
	processed_upgrades_by_tier[upgrade_tier] += 1

func on_item_received(item_name: String, _item):
	if item_name in constants.UPGRADE_NAME_TO_TIER:
		var upgrade_tier = constants.UPGRADE_NAME_TO_TIER[item_name]
		received_upgrades_by_tier[upgrade_tier] += 1
		
		# If we received an item, that means we're connected to a multiworld.
		# No reason to check if connected or in a run
		emit_signal("upgrade_received", upgrade_tier)

func on_run_started(_character_id: String):
	# Reset the number of upgrades processed
	processed_upgrades_by_tier = {
		Tier.COMMON: 0,
		Tier.UNCOMMON: 0,
		Tier.RARE: 0,
		Tier.LEGENDARY: 0
	}
