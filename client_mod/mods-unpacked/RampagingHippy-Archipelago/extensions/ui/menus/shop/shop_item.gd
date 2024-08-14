extends "res://ui/menus/shop/shop_item.gd"


func enable_lock_button():
	_lock_button.disabled = false
	_lock_button.text = "MENU_LOCK"

func disable_lock_button():
	_lock_button.disabled = true
	_lock_button.text = "Need item"