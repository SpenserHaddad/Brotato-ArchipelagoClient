## Receive Brotato items from Archipelago items, and give them to the player.
##
## Note: Assume "items" are Brotato items (weapons/passives/etc.) unless we specifically
## say "Archipelago items", which are the multiworld items received as part of a
## "ReceivedItems" command.
##
## Listen to the client for items received as Archipelago items, then give them to the
## player immediately if they're in a run, or as soon as they start a new run.
##
## Items are given to the player every run, so we track the total amount of items and
## give them all to the player every time they start a run.
##
## When we receive an item from Archipelago, we don't actually know what in-game item it
## is. Trying to choose from the pool of all Brotato items in the randomizer is
## impractical, so we use Brototo's existing item drop logic to create teh actual item.
##
## When creating an item, Brotato randomly selects from a pool of items based off the
## item's rarity/tier (Common, Uncommon, Rare, or Legendary), and the current wave of
## the run. There are Archipelago items for each Brotato item rarity, which is passed to
## the item selection as-is. For the wave, we assign each item to a wave in Archipelago
## save the information to slot_data, and then reference that data here.
extends ApProgressBase
class_name ApItemsProgress

signal item_received(item_tier)

var received_items_by_tier: Dictionary = {
	Tier.COMMON: 0,
	Tier.UNCOMMON: 0,
	Tier.RARE: 0,
	Tier.LEGENDARY: 0
}

# The number of items processed in the currennt run. This is set at the start of each
# run to keep track of how many items the player has received from items so far so we
# can set the level of each item correctly.
var processed_items_by_tier: Dictionary

var wave_per_game_item: Dictionary

func _init(ap_client, game_state).(ap_client, game_state):
	# Need this for Godot to pass through to the base class
	pass

func process_ap_item(item_tier: int) -> int:
	## Called when AP consumables are processed at the end of the round for each item.
	## This increments the number of items processed this run, then returns the wave to
	## use to determine the item to give.
	##
	## The returned value won't necessarily match the current wave. The "<rarity> Item"
	## items in the multiworld are meant to be evenly distributed over 20 waves, which
	## is what this function handles.
	var next_item_wave = processed_items_by_tier[item_tier] + 1
	processed_items_by_tier[item_tier] = next_item_wave

	# Lookup the wave to use to determine the item 
	var wave = wave_per_game_item[item_tier][next_item_wave]
	return wave

func on_item_received(item_name: String, _item):
	if item_name in constants.ITEM_DROP_NAME_TO_TIER:
		var item_tier = constants.ITEM_DROP_NAME_TO_TIER[item_name]
		received_items_by_tier[item_tier] += 1
		
		# If we received an item, that means we're connected to a multiworld.
		# No reason to check if connected or in a run
		emit_signal("item_received", item_tier)

func on_connected_to_multiworld():
	wave_per_game_item = _ap_client.slot_data["wave_per_game_item"]

func on_run_started(_character_id: String):
	# Reset the number of items processed
	processed_items_by_tier = {
		Tier.COMMON: 0,
		Tier.UNCOMMON: 0,
		Tier.RARE: 0,
		Tier.LEGENDARY: 0
	}
