extends "res://ui/menus/shop/shop_item.gd"

var _ap_lock_button_enabled: bool = true

func activate():
	.activate()
	
	# Activate always enables the lock button, so we may have to set it back to it's AP
	# value.
	if not _ap_lock_button_enabled:
		disable_lock_button()

func enable_lock_button():
	_lock_button.activate()
	_lock_button.text = "MENU_LOCK"
	_ap_lock_button_enabled = true

func disable_lock_button():
	_lock_button.disable()
	_lock_button.text = "Need item"
	_ap_lock_button_enabled = false
