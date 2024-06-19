extends Object
class_name ApProgressBase

const BrotatoApConstants = preload ("../singletons/constants.gd")
const GodotApClient = preload ("../singletons/godot_ap_client.gd")

var _ap_client
var _game_state
var constants = BrotatoApConstants.new()

# Called when the node enters the scene tree for the first time.
func _init(ap_session, game_state):
	_ap_client = ap_session
	_game_state = game_state
	var _status = _ap_client.connect("connection_state_changed", self, "_on_session_connection_state_changed")
	_status = _ap_client.connect("item_received", self, "on_item_received")
	_status = _ap_client.connect("room_updated", self, "on_room_updated")
	_status = _game_state.connect("run_started", self, "on_run_started")

func on_item_received(_item_name: String, _item):
	pass

func on_connected_to_multiworld():
	pass

func on_run_started(_character_id: String):
	pass

func on_wave_finished(_wave: int, _character_id: String):
	pass

func _on_session_connection_state_changed(state: int, _error: int=0):
	if state == GodotApClient.ConnectState.CONNECTED_TO_MULTIWORLD:
		on_connected_to_multiworld()
