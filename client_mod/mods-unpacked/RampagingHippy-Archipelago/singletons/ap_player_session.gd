extends Node
class_name ApPlayerSession
# Hard-code mod name to avoid cyclical dependency
var LOG_NAME = "RampagingHippy-Archipelago/ap_player_session"

const _AP_TYPES = preload("./ap_types.gd")
enum ConnectState {
	DISCONNECTED = 0
	CONNECTING = 1
	DISCONNECTING = 2  
	CONNECTED_TO_SERVER = 3
	CONNECTED_TO_MULTIWORLD = 4
}

enum ConnectResult {
	SUCCESS = 0
	SERVER_CONNECT_FAILURE = 1
	PLAYER_NOT_SET = 2
	GAME_NOT_SET = 3
	INVALID_SERVER = 4
	# The following correspond to the errors the AP ConnectionRefused message can send.
	AP_INVALID_SLOT = 5
	AP_INVALID_GAME = 6
	AP_INCOMPATIBLE_VERSION = 7
	AP_INVALID_PASSWORD = 8
	AP_INVALID_ITEMS_HANDLING = 9
	# Fallback in case a new error is added that we don't support yet
	AP_CONNECTION_REFUSED_UNKNOWN_REASON = 10
	ALREADY_CONNECTED = 11
}

class ApDataPackage:
	var item_name_to_id: Dictionary
	var location_name_to_id: Dictionary
	var item_id_to_name: Dictionary
	var location_id_to_name: Dictionary
	var version: int
	var checksum: String

	func _init(data_package_object: Dictionary):
		version = data_package_object["version"]
		checksum = data_package_object["checksum"]
		item_name_to_id = data_package_object["item_name_to_id"]
		location_name_to_id = data_package_object["location_name_to_id"]

		item_id_to_name = Dictionary()
		for item_name in item_name_to_id:
			var item_id = item_name_to_id[item_name]
			item_id_to_name[item_id] = item_name
			
		location_id_to_name = Dictionary()
		for location_name in location_name_to_id:
			var location_id = location_name_to_id[location_name]
			location_id_to_name[location_id] = location_name


var websocket_client: ApWebSocketConnection
var connect_state = ConnectState.DISCONNECTED
var player: String = ""
var server: String = "archipelago.gg"
var game: String = ""

var team: int
var slot: int
var players: Array
var missing_locations: PoolIntArray
var checked_locations: PoolIntArray
var slot_data: Dictionary
var slot_info: Dictionary
var hint_points: int

var room_info: Dictionary
var data_package: ApDataPackage

signal _received_connect_response(message)
signal connection_state_changed(state, error)
signal item_received(item_name, item)

func _init(websocket_client_):
	self.websocket_client = websocket_client_

func _ready():
	var _status: int
	_status = websocket_client.connect("on_received_items", self, "_on_received_items")

func _connected_or_connection_refused_received(message: Dictionary):
	emit_signal("_received_connect_response", message)

func connect_to_multiworld(password: String = "", get_data_pacakge: bool = true) -> int:
	if websocket_client.connected_to_multiworld():
		return ConnectResult.ALREADY_CONNECTED
	elif player.strip_edges().empty():
		return ConnectResult.PLAYER_NOT_SET
	elif server.strip_edges().empty():
		return ConnectResult.INVALID_SERVER
	elif server.strip_edges().empty():
		return ConnectResult.GAME_NOT_SET

	_set_connection_state(ConnectState.CONNECTING)

	# Go through the handshake at below in order:
	# https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#archipelago-connection-handshake

	# 1. Client establishes WebSocket connection to the Archipelago server.
	var funcstate = websocket_client.connect_to_server(server)
	var server_connect_result = yield(funcstate, "completed")

	if server_connect_result == false:
		_set_connection_state(ConnectState.DISCONNECTED, ConnectResult.SERVER_CONNECT_FAILURE)
		return ConnectResult.SERVER_CONNECT_FAILURE
	else:
		_set_connection_state(ConnectState.CONNECTED_TO_SERVER)
		connect_state = ConnectState.CONNECTED_TO_SERVER
	
	# 2. Server accepts connection and responds with a RoomInfo packet.
	room_info = yield(websocket_client, "on_room_info")

	# 3. Client may send a GetDataPackage packet.
	if get_data_pacakge:
		websocket_client.get_data_package([game])
		# 4. Server sends a DataPackage packet in return. (If the client sent GetDataPackage.)
		var data_package_message = yield(websocket_client, "on_data_package")
		data_package = ApDataPackage.new(data_package_message["data"]["games"][self.game])

	# 5. Client sends Connect packet in order to authenticate with the server.
	# 6. Server validates the client's packet and responds with Connected or ConnectionRefused.

	# Wait for the first response the server sends back
	var _result = websocket_client.connect(
		"on_connected",
		self,
		"_connected_or_connection_refused_received"
	)
	_result = websocket_client.connect(
		"on_connection_refused", 
		self,
		"_connected_or_connection_refused_received"
	)
	if room_info.password:
		websocket_client.send_connect(game, player, password)
	else:
		websocket_client.send_connect(game, player)
	var connect_response = yield(self, "_received_connect_response")

	if connect_response["cmd"] == "ConnectionRefused":
		# There may be multiple errors, but there isn't a clean way in Godot to return
		# them all. Just return the first error the multiworld server sent us.
		var ap_error: int
		match connect_response["errors"][0]:
			"InvalidSlot":
				ap_error = ConnectResult.AP_INVALID_SLOT
			"InvalidGame":
				ap_error = ConnectResult.AP_INVALID_GAME
			"IncompatibleVersion":
				ap_error = ConnectResult.AP_INCOMPATIBLE_VERSION
			"InvalidPassword":
				ap_error = ConnectResult.AP_INVALID_PASSWORD
			"InvalidItemsHandling":
				ap_error = ConnectResult.AP_INVALID_ITEMS_HANDLING
			_:
				ap_error = ConnectResult.AP_CONNECTION_REFUSED_UNKNOWN_REASON
		self._set_connection_state(self.connect_state, ap_error)
		return ap_error

	self.team = connect_response["team"]
	self.slot = connect_response["slot"]
	self.players = connect_response["players"]
	self.missing_locations = connect_response["missing_locations"]
	self.checked_locations = connect_response["checked_locations"]
	self.slot_data = connect_response["slot_data"]
	self.slot_info = connect_response["slot_info"]
	self.hint_points = connect_response["hint_points"]

	# The last two steps are handled by signal handlers and other classes.
	# 7. Server may send ReceivedItems to the client, in the case that the client is missing items that are queued up for it.
	# 8. Server sends PrintJSON to all players to notify them of the new client connection.

	_set_connection_state(ConnectState.CONNECTED_TO_MULTIWORLD)
	return ConnectResult.SUCCESS

func disconnect_from_multiworld():
	_set_connection_state(ConnectState.DISCONNECTING)
	self.websocket_client.disconnect_from_server()
	_set_connection_state(ConnectState.DISCONNECTED)

func _set_connection_state(state: int, error: int = 0):
	ModLoaderLog.debug("Setting connection state to %s." % ConnectState.keys()[state], LOG_NAME)
	self.connect_state = state
	emit_signal("connection_state_changed", self.connect_state, error)

func set_status(status: int):
	# TODO: bounds checking
	websocket_client.status_update(status)

func check_location(location_id: int):
	# TODO: allow name or id?
	websocket_client.send_location_checks([location_id])

func _on_received_items(command):
	# TODO: update missing and checked locations?
	var items = command["items"]
	for item in items:
		var item_name = null
		if self.data_package:
			item_name = data_package.item_id_to_name[item["item"]]
		emit_signal("item_received", item_name, item)
