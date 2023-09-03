extends "res://ui/menus/pages/main_menu.gd"

onready var _archipelago_button

signal ap_connect_button_pressed

func init():
	.init()


func _ready():
	._ready()
	_add_ap_button()


func _add_ap_button():
	var parent_node_name = "HBoxContainer/ButtonsLeft"
	var parent_node: BoxContainer = get_node(parent_node_name)

	ModLoaderMod.append_node_in_scene(self,
		"ArchipelagoButton",
		parent_node_name,
		"res://mods-unpacked/RampagingHippy-Archipelago/ui/menus/pages/archipelago_connect_button.tscn"
	)
	_archipelago_button = get_node(parent_node_name + "/ArchipelagoButton")
	parent_node.move_child(_archipelago_button, 0)
	_archipelago_button.connect("pressed", self, "_on_MainMenu_ap_connect_button_pressed")

func _on_MainMenu_ap_connect_button_pressed() -> void:
	emit_signal("ap_connect_button_pressed")
