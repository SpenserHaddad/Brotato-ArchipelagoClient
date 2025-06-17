extends "res://ui/menus/shop/shop.gd"

const LOG_NAME = "RampagingHippy-Archipelago/ui/menus/shop/shop"
const ApGoToWaveMenu = preload("res://mods-unpacked/RampagingHippy-Archipelago/ui/menus/shop/ap_go_to_wave_menu.tscn")

onready var _ap_client


func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client
	if _ap_client.connected_to_multiworld():
		_add_ap_go_to_wave_button()

func _add_ap_go_to_wave_button():
	var parent_node: Container = $Content/MarginContainer/HBoxContainer/VBoxContainer2

	ModLoaderMod.append_node_in_scene(
		self, "ApGoToWave", parent_node.get_path(), ApGoToWaveMenu.resource_path
	)
