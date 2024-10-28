extends "res://ui/menus/shop/shop_item.gd"

var ap_lock_button_enabled: bool = true

func manage_lock_button_visibility() -> void:
	.manage_lock_button_visibility()

	# The game may disable the lock button using certain items, we need to make sure we
	# don't override this.
	if not ap_lock_button_enabled and not _lock_button.disabled:
		_lock_button.disable()
		_lock_button.text = "Need item"
	else:
		# Trust that the game has set the lock button properly, just set the text back
		# in case we changed it before and received an lock button item from AP.
		_lock_button.text = "MENU_LOCK"

	
		
