extends "res://ui/menus/title_screen/title_screen_menus.gd"

const LOG_NAME = "RampagingHippy-Archipelago/title_screen_menus"
var _custom_menu_ap_connect

func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_custom_menu_ap_connect = load("res://mods-unpacked/RampagingHippy-Archipelago/ui/menus/pages/menu_ap_connect.tscn").instance()
	add_child(_custom_menu_ap_connect)
	_custom_menu_ap_connect.visible = false
	_custom_menu_ap_connect.connect("back_button_pressed", self, "_on_MenuAp_back_button_pressed")
	# var _main_menu: MainMenu = get_node("MarginContainer/Menus/MainMenu")
	var _foo = _main_menu.connect("ap_connect_button_pressed", self, "_on_MainMenu_ap_connect_button_pressed")

func _on_MainMenu_ap_connect_button_pressed() -> void:
	ModLoaderLog.debug("Switching to AP Connect menu", LOG_NAME)
	switch(_main_menu, _custom_menu_ap_connect)

func _on_MenuAp_back_button_pressed() -> void:
	ModLoaderLog.debug("Switching from AP Connect menu to main menu", LOG_NAME)
	switch(_custom_menu_ap_connect, _main_menu)
