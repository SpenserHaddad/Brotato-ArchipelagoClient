extends "res://ui/menus/pages/main_menu.gd"

onready var _archipelago_button
onready var _ap_websocket_connection
var _ap_icon_connected = preload("res://mods-unpacked/RampagingHippy-Archipelago/ap_button_icon_connected.png")
var _ap_icon_disconnected = preload("res://mods-unpacked/RampagingHippy-Archipelago/ap_button_icon_disconnected.png")

signal ap_connect_button_pressed

func init():
	.init()

func _ready():
	._ready()
	_ap_websocket_connection = get_node("/root/ModLoader/RampagingHippy-Archipelago").ap_websocket_connection
	var _success = _ap_websocket_connection.connect("connection_state_changed", self, "_set_ap_button_icon")
	_add_ap_button()
	_set_ap_button_icon(_ap_websocket_connection.connection_state)

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

func _set_ap_button_icon(ws_state: int):
	var icon: Texture
	# ApWebSocketConnection.State.STATE_OPEN, can't use directly because of dynamic loading
	if ws_state == 1:
		icon = _ap_icon_connected
	else:
		icon = _ap_icon_disconnected
	_archipelago_button.icon = icon

func _on_MainMenu_ap_connect_button_pressed() -> void:
	emit_signal("ap_connect_button_pressed")
