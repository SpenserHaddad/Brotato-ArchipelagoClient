extends Object
class_name ApProgressBase

const BrotatoApConstants = preload ("../singletons/constants.gd")
const ApPlayerSession = preload ("../singletons/ap_player_session.gd")

var _ap_session
var _game_state
var constants = BrotatoApConstants.new()

# Called when the node enters the scene tree for the first time.
func _init(ap_session, game_state):
	_ap_session = ap_session
	_game_state = game_state
	var _status = _ap_session.connect("connection_state_changed", self, "_on_session_connection_state_changed")
	_status = _ap_session.connect("item_received", self, "on_item_received")
	_status = _ap_session.connect("room_updated", self, "on_room_updated")

func on_item_received(_item_name: String, _item):
	return

func on_connected_to_multiworld():
	pass

func _on_session_connection_state_changed(state: int, _error: int=0):
	if state == ApPlayerSession.ConnectState.CONNECTED_TO_MULTIWORLD:
		on_connected_to_multiworld()
