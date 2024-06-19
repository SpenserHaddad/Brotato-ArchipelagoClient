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

func _init(ap_session, game_state).(ap_session, game_state):
	# Need this for Godot to pass through to the base class
	pass

func process_ap_item(item_tier: int) -> int:
	## Called when consumables are processed at the end of the round for each item. This
	## increments the number of items processed this run, then returns the wave to use
	## to determine the item to give.
	##
	## The returned value won't necessarily match the current wave. The "<rarity> Item"
	## items in the multiworld are meant to be evenly distributed over 20 waves, which
	## is what this function handles.
	processed_items_by_tier[item_tier] += 1
	# 20 being the total number of waves.
	# TODO: Actually space out items
	return int(ceil(processed_items_by_tier[item_tier] / constants.NUM_ITEM_DROPS_PER_WAVE)) % 20

func on_item_received(item_name: String, _item):
	if item_name in constants.ITEM_DROP_NAME_TO_TIER:
		var item_tier = constants.ITEM_DROP_NAME_TO_TIER[item_name]
		received_items_by_tier[item_tier] += 1
		
		# If we received an item, that means we're connected to a multiworld.
		# No reason to check if connected or in a run
		emit_signal("item_received", item_tier)

func on_run_started(_character_id: String):
	# Reset the number of items processed
	processed_items_by_tier = {
		Tier.COMMON: 0,
		Tier.UNCOMMON: 0,
		Tier.RARE: 0,
		Tier.LEGENDARY: 0
	}