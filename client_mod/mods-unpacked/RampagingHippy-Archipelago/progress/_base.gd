## Base class for tracking various parts of multiworld progress for the player
## 
## Progress classes sit between the AP client and the Brotato extensions. They receive
## notifications from both sides-from the AP client via signals, and from the extensions
## by direct function calls, and either store the state or relay the information to the
## other side.
##
## "Progress" in this case means any specific data used in Brotato Archipelago, such as
## gold, XP, items, and the number of wins made. Most of the logic for updating the
## client and game state lives in the sub-classes, with the other parts reacting to
## changes here.
##
## This base class comes with a few convenience methods and boilerplate that's commonly
## used by its sub-classes. Sub-classes should feel free to connect to additional
## signals on the game state or AP client if necessary.
extends Object
class_name ApProgressBase

const BrotatoApConstants = preload("../ap/constants.gd")
const GodotApClient = preload("res://mods-unpacked/RampagingHippy-Archipelago/ap/godot_ap_client.gd")

var _ap_client: GodotApClient
## A BrotatoApClient instance which sub-classes can use to send/receive updates from the
## multiworld.

## An ApGameState instance which sub-classes can use to query when runs/waves are
## started or ended.
var _game_state

## A BrotatoApConstants instance.
var constants = BrotatoApConstants.new()

func _init(ap_client, game_state):
	## Initialize the progress tracker
	##
	## Takes GodotAPClient and ApGameState instances as inputs, which are made available
	_ap_client = ap_client
	_game_state = game_state
	var _status = _ap_client.connect("connection_state_changed", self, "_on_client_connection_state_changed")
	_status = _ap_client.connect("item_received", self, "on_item_received")
	_status = _ap_client.connect("room_updated", self, "on_room_updated")
	_status = _ap_client.connect("data_storage_updated", self, "on_data_storage_updated")
	_status = _game_state.connect("run_started", self, "on_run_started")
	_status = _game_state.connect("wave_finished", self, "on_wave_finished")

func export_run_specific_progress_data() -> Dictionary:
	## Get any run-specific state to the input dictionary.
	##
	## Intended to be used to build up AP-related data when saving a run. The output
	## dictionary will be merged with those from other trackers, so make sure to use
	## unique key names.
	return {}

func load_run_specific_progress_data(_data: Dictionary):
	pass

func on_item_received(_item_name: String, _item):
	pass

func on_room_updated(_room_update: Dictionary):
	pass

func on_connected_to_multiworld():
	pass

func on_disconnected_from_multiworld():
	pass

func on_run_started(_character_ids: Array):
	pass

func on_wave_finished(_wave_number: int, _character_ids: Array, _is_run_lost: bool, _is_run_won: bool):
	pass

func on_data_storage_updated(_key: String, _new_value, _original_valeu = null):
	pass

func _on_client_connection_state_changed(state: int, _error: int = 0):
	if state == GodotApClient.ConnectState.CONNECTED_TO_MULTIWORLD:
		on_connected_to_multiworld()
	elif state == GodotApClient.ConnectState.DISCONNECTED:
		on_disconnected_from_multiworld()
