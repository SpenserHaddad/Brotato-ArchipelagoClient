extends ApProgressBase
class_name ApItemsProgress

signal item_received(item_tier)

func _init(ap_session).(ap_session):
	# Need this to tell Godot about the base class constructor
	return

var received_items_by_tier: Dictionary = {
	Tier.COMMON: 0,
	Tier.UNCOMMON: 0,
	Tier.RARE: 0,
	Tier.LEGENDARY: 0
}

func on_item_received(item_name: String, _item):
	if item_name in constants.ITEM_DROP_NAME_TO_TIER:
		var item_tier = constants.ITEM_DROP_NAME_TO_TIER[item_name]
		received_items_by_tier[item_tier] += 1
		
		# If we received an item, that means we're connected to a multiworld.
		# No reason to check if connected or in a run
		emit_signal("item_received", item_tier)
