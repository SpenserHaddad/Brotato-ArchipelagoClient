## Track the number of shop slots unlocked from Archipelago items.
extends "res://mods-unpacked/RampagingHippy-Archipelago/progress/_base.gd"
class_name ApShopLockButtonsProgress

const LOG_NAME = "RampagingHippy-Archipelago/progress/shop_lock_buttons"

var num_starting_shop_lock_buttons: int
var num_unlocked_shop_lock_buttons: int

signal shop_lock_button_item_received

func _init(ap_client, game_state).(ap_client, game_state):
	# Need this for Godot to pass through to the base class
	pass

func on_item_received(item_name: String, _item):
	if item_name == constants.SHOP_LOCK_BUTTON_ITEM_NAME:
		num_unlocked_shop_lock_buttons += 1
		ModLoaderLog.info("Shop lock button received, count=%d" % num_unlocked_shop_lock_buttons, LOG_NAME)
		emit_signal("shop_lock_button_item_received")

func on_connected_to_multiworld():
	num_starting_shop_lock_buttons = _ap_client.slot_data["num_starting_shop_lock_buttons"]
	num_unlocked_shop_lock_buttons = num_starting_shop_lock_buttons
	ModLoaderLog.info(
		"num_starting_shop_lock_buttons=%d, num_unlocked_shop_lock_buttons=%d" % 
		[num_starting_shop_lock_buttons, num_unlocked_shop_lock_buttons], 
		LOG_NAME
	)