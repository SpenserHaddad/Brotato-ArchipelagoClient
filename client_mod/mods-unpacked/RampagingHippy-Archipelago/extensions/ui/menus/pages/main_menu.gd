extends "res://ui/menus/pages/main_menu.gd"

const LOG_NAME = "RampagingHippy-Archipelago/main_menu"

onready var _archipelago_button
onready var _ap_websocket_connection
onready var _ap_client
var _ap_icon_connected = preload("res://mods-unpacked/RampagingHippy-Archipelago/images/ap_logo_80.png")
var _ap_icon_disconnected = preload("res://mods-unpacked/RampagingHippy-Archipelago/images/ap_logo_80_greyscale.png")

signal ap_connect_button_pressed

func init():
	.init()

	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client

	if _archipelago_button != null:
		# Make AP button reachable with controller. Because we setup Quit -> AP in
		# _init() Godot inheritance/call-order rules means we have to set the neighbor
		# here for it take.
		quit_button.focus_neighbour_bottom = _archipelago_button.get_path()
		var bottom_neighbor
		if ProgressData.saved_run_state.get("has_run_state", false):
			bottom_neighbor = continue_button
		else:
			bottom_neighbor = start_button

		_archipelago_button.focus_neighbour_top = quit_button.get_path()
		_archipelago_button.focus_neighbour_bottom = bottom_neighbor.get_path()
		bottom_neighbor.focus_neighbour_top = _archipelago_button.get_path()

	if (
			_ap_client.connected_to_multiworld() and 
			ProgressData.saved_run_state.has_run_state and
			_ap_client.config.data["has_saved_run"]
		):
		var saved_run_characters = ProgressData.saved_run_state.players_data
		var saved_run_last_wave = ProgressData.saved_run_state["current_wave"]
		if (_ap_client.config.data["saved_run_characters"] != saved_run_characters or
			_ap_client.config.data["saved_run_wave"] != saved_run_last_wave):
			ModLoaderLog.info("Saved run does not AP's saved run, disabling resume button.", LOG_NAME)
			continue_button.disabled = true
			

func _ready():
	._ready()
	_ap_websocket_connection = get_node("/root/ModLoader/RampagingHippy-Archipelago").ap_websocket_connection
	var _success = _ap_websocket_connection.connect("connection_state_changed", self, "_set_ap_button_icon")
	_add_ap_button()
	_set_ap_button_icon(_ap_websocket_connection.connection_state)

func _add_ap_button():
	var parent_node: Container = $MarginContainer/VBoxContainer/HBoxContainer/ButtonsLeft

	ModLoaderMod.append_node_in_scene(
		self,
		"ArchipelagoButton",
		parent_node.get_path(),
		"res://mods-unpacked/RampagingHippy-Archipelago/ui/menus/pages/archipelago_connect_button.tscn"
	)
	_archipelago_button = parent_node.get_node("ArchipelagoButton")
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
