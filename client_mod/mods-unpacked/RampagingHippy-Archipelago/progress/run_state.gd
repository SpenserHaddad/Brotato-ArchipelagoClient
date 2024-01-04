# Archipelago-specific information about the currently active run.
extends Object
class_name ApRunState

# Keep track of how many AP items were dropped each wave but haven't been picked up,
# and therefore their locations have not been sent. This helps us to not drop more
# AP items than there are locations for.
var ap_consumables_not_picked_up = 0
var ap_legendary_consumables_not_picked_up = 0

# Track items received from the server so we can process them at the end of a wave.
var gift_item_count_by_tier: Dictionary = {
	Tier.COMMON: 0,
	Tier.UNCOMMON: 0,
	Tier.RARE: 0,
	Tier.LEGENDARY: 0
}

func wave_started():	
	## Reset any wave-specific fields when a new wave starts.
	self.ap_consumables_not_picked_up = 0
	self.ap_legendary_consumables_not_picked_up = 0
