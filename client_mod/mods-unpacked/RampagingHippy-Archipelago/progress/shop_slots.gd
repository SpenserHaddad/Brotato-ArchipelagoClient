## Track the number of shop slots unlocked from Archipelago items.
extends "res://mods-unpacked/RampagingHippy-Archipelago/progress/_base.gd"
class_name ApShopSlotsProgress

var num_starting_shop_slots: int
var num_unlocked_shop_slots: int

func _init(ap_client, game_state).(ap_client, game_state):
	# Need this for Godot to pass through to the base class
	pass

func on_item_received(item_name: String, _item):
	if item_name == constants.SHOP_SLOT_ITEM_NAME:
		num_unlocked_shop_slots += 1

func on_connected_to_multiworld():
	num_starting_shop_slots = _ap_client.slot_data["num_starting_shop_slots"]
	num_unlocked_shop_slots = num_starting_shop_slots
