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
	_update_lock_buttons()

func _update_lock_buttons():
	for shop_item_idx in range(_shop_items.size()):
		var shop_item = _shop_items[shop_item_idx]
		if shop_item_idx < _lock_buttons_progress.num_unlocked_shop_lock_buttons:
			shop_item.enable_lock_button()
		else:
			shop_item.disable_lock_button()
