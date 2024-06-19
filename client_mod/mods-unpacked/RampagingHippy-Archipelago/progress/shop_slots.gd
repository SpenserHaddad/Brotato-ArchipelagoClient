extends ApProgressBase
class_name ApShopSlotsProgress

var num_starting_shop_slots: int
var num_unlocked_shop_slots: int
var wins_for_goal: int
var num_wins: int = 0
var characters_won_with: PoolStringArray = []

func _init(ap_session).(ap_session):
	_ap_session = ap_session

func on_item_received(item_name: String, _item):
	if item_name == constants.SHOP_SLOT_ITEM_NAME:
		num_unlocked_shop_slots += 1

func on_connected_to_multiworld():
	num_starting_shop_slots = _ap_session.slot_data["num_starting_shop_slots"]
	num_unlocked_shop_slots = num_starting_shop_slots
