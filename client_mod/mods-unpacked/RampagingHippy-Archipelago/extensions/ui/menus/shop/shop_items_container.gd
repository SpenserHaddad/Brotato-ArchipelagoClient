extends "res://ui/menus/shop/shop_items_container.gd"

const LOG_NAME = "RampagingHippy-Archipelago/shop_items_container"

var _ap_client
var _lock_buttons_progress

func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client
	_lock_buttons_progress = _ap_client.shop_lock_buttons_progress
	_lock_buttons_progress.connect(
		"shop_lock_button_item_received",
		self,
		"_update_lock_buttons"
	)
	if _ap_client.connected_to_multiworld():
		_update_lock_buttons()

func _update_lock_buttons():
	ModLoaderLog.info("Updating lock buttons", LOG_NAME)
	for shop_item_idx in range(_shop_items.size()):
		var shop_item = _shop_items[shop_item_idx]
		shop_item.ap_lock_button_enabled = shop_item_idx < _lock_buttons_progress.num_unlocked_shop_lock_buttons
		ModLoaderLog.info("slot %d: lock_button_enabled=%s" % [shop_item_idx, shop_item.ap_lock_button_enabled], LOG_NAME)
		shop_item.manage_lock_button_visibility()
