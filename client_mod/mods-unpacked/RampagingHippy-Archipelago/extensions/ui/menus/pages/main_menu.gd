extends "res://ui/menus/pages/main_menu.gd"

const LOG_NAME = "RampagingHippy-Archipelago/main_menu"
const ApConnectButton = preload("res://mods-unpacked/RampagingHippy-Archipelago/ui/menus/pages/archipelago_connect_button.tscn")
const _ap_load_saved_run_scene = "res://mods-unpacked/RampagingHippy-Archipelago/ui/menus/run/load_ap_run.tscn"

onready var _archipelago_button
onready var _ap_websocket_connection
onready var _ap_client
var _ap_icon_connected = preload("res://mods-unpacked/RampagingHippy-Archipelago/images/ap_logo_80.png")
var _ap_icon_disconnected = preload("res://mods-unpacked/RampagingHippy-Archipelago/images/ap_logo_80_greyscale.png")

signal ap_connect_button_pressed

func init():
	if _archipelago_button != null:
		# Make AP button reachable with controller. The base class also sets the neighbors for some
		# of these buttons in its _init(), so we have to set the neighbor her for it to be applied.
		var bottom_neighbor
		if ProgressData.saved_run_state.has_run_state:
			bottom_neighbor = continue_button
		else:
			bottom_neighbor = start_button

		quit_button.focus_neighbour_bottom = quit_button.get_path_to(_archipelago_button)
		_archipelago_button.focus_neighbour_top = quit_button.get_path()
		
		# This will trigger in the base class' init(), which is called after this one's.
		continue_button.connect("visibility_changed", self, "_on_ContinueButton_visibility_changed")


func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client
	
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
		ApConnectButton.resource_path
	)
	_archipelago_button = parent_node.get_node("ArchipelagoButton")
	parent_node.move_child(_archipelago_button, 0)
	_archipelago_button.connect("pressed", self, "_on_MainMenu_ap_connect_button_pressed")
	_archipelago_button.set_focus_mode(FOCUS_ALL)

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

func _on_ContinueButton_pressed() -> void:
	if _ap_client.connected_to_multiworld():
		var last_saved_run = _ap_client.saved_runs_progress.get_last_saved_run()
		if last_saved_run == {}:
			ModLoaderLog.warning("Tried to resume game without an AP saved run!", LOG_NAME)
			return
			
		var iser = ItemService.characters
		
		var players_data = last_saved_run["game_state"]["players_data"]
		for player_idx in range(len(players_data)):
			var player_character_id = players_data[player_idx]["current_character"]
			var player_character = null
			for character in iser:
				if character.my_id == player_character_id:
					player_character = character
					break
			if player_character == null:
				ModLoaderLog.warning("Tried to resume game with unknown character %s." % player_character_id, LOG_NAME)
				return
			RunData.add_character(player_character, player_idx)
		get_tree().change_scene(_ap_load_saved_run_scene)
	else:
		._on_ContinueButton_pressed()

func _on_ContinueButton_visibility_changed() -> void:
	# Make sure the "Resume" button is visible is correct.
	# If not connected to AP, use the base game's behavior. Otherwise, the button should only appear
	# when there's a saved AP run. We can't just call this in init(), because the base class also
	# sets the visibility of the Resume button in its init(), which is called after ours.
	var ap_button_bottom_neighbor = continue_button
	if continue_button.visible and _ap_client.connected_to_multiworld():
		var have_saved_ap_run = _ap_client.saved_runs_progress.get_last_played_char() != ""
		if not have_saved_ap_run:
			continue_button.hide()
			ap_button_bottom_neighbor = start_button
	
	_archipelago_button.focus_neighbour_bottom = ap_button_bottom_neighbor.get_path()
	ap_button_bottom_neighbor.focus_neighbour_top = _archipelago_button.get_path()
	# For some reason, the neighbors don't update unless focus on the AP button first.
	# Force the focus to the AP button to make nav work, which also is nice for letting the
	# user connect to a server first if desired.
	_archipelago_button.grab_focus()
