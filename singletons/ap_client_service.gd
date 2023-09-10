extends Node
class_name ApClientService
const LOG_NAME = "AP Client"

var _client = WebSocketClient.new()
var _peer: WebSocketPeer
var _game: String
var _user: String
var _password: String

var _connected_to_multiworld = false

enum State {
	STATE_CONNECTING = 0
	STATE_OPEN = 1
	STATE_CLOSING = 2
	STATE_CLOSED = 3
}
signal connection_state_changed

var connection_state = State.STATE_CLOSED

signal item_received
signal on_room_info
signal on_connected
signal on_connection_regused
signal on_received_items
signal on_location_info
signal on_room_update
signal on_print_json
signal on_data_package
signal on_bounced
signal on_invalid_packet
signal on_retrieved
signal on_set_reply


func _init(game: String):
	_game = game

func _ready():
	# Connect base signals to get notified of connection open, close, and errors.
	_client.connect("connection_closed", self, "_closed")
	_client.connect("connection_error", self, "_closed")
	_client.connect("connection_established", self, "_connected")
	_client.connect("data_received", self, "_on_data")
	ModLoaderLog.info("AP Client Ready!", "RampagingHippy-Archipelago")
	set_process(false)

# Public API

func connect_to_multiworld(server: String, port: int, user: String, password: String = ""):
	_set_connection_state(State.STATE_CONNECTING)
	var url = "ws://%s:%d" % [server, port]
	ModLoaderLog.info("Connecting to %s" % url, LOG_NAME)
	var err = _client.connect_to_url("ws://%s:%d" % [server, port])
	ModLoaderLog.info("Connect Results: " + str(err), LOG_NAME)
	if not err:
		_user = user
		_password = password
		_peer = _client.get_peer(1)
		_peer.set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
		set_process(true)

func send_location_checks(locations: Array):
	_send_command(
		{
			"cmd": "LocationChecks",
			"locations": locations,
		}
	)

# TODO: create_as_hint Enum
func send_location_scouts(locations: Array, create_as_int: int):
	_send_command({
		"cmd": "LocationScouts",
		"locations": locations,
		"create_as_int": create_as_int
	})


# TODO: ClientStatus enum
func status_update(client_status: int):
	_send_command({
		"cmd": "StatusUpdate",
		"client_status": client_status,
	})

func say(text: String):
	_send_command({
		"cmd": "Say",
		"text": text,
	})

func get_data_package(games: Array):
	_send_command({
		"cmd": "GetDataPackage",
		"games": games,
	})

func bounce(games: Array, slots: Array, tags: Array, data: Dictionary):
	_send_command({
		"cmd": "Bounce",
		"games": games,
		"slots": slots,
		"tags": tags,
		"data": data,
	})

# TODO: Extra custom arguments
func get_value(keys: Array):
	# This is Archipelago's "Get" command, we change the name 
	# since "get" is already taken by "Object.get".
	_send_command({
		"cmd": "Get",
		"keys": keys,
	})

# TODO: DataStorageOperation data type
func set_value(key: String, default, want_reply: bool, operations: Array):
	_send_command({
		"cmd": "Set",
		"key": key,
		"default": default,
		"want_reply": want_reply,
		"operations": operations,
	})

func set_notify(keys: Array):
	_send_command({
		"cmd": "SetNotify",
		"keys": keys,
	})

# Websocket callbacks
func _send_command(args: Dictionary):
	var command_str = JSON.print([args])
	var _result = _peer.put_packet(command_str.to_ascii())

func _closed(was_clean = false):
	_set_connection_state(State.STATE_CLOSED)
	ModLoaderLog.info("AP connection closed, clean: %s" % was_clean, LOG_NAME)
	set_process(false)

func _connected(proto = ""):
	_set_connection_state(State.STATE_OPEN)
	ModLoaderLog.info("AP connection opened with protocol: %s" % proto, LOG_NAME)

func _set_connection_state(state):
	ModLoaderLog.info("AP connection state changed to: %d" % state, LOG_NAME)
	connection_state = state
	emit_signal("connection_state_changed", connection_state)

func _on_data():
	var received_data_str = _peer.get_packet().get_string_from_utf8()
	var received_data = JSON.parse(received_data_str)
	# ModLoaderLog.debug_json_print("Got data from server", received_data_str, LOG_NAME)
	for command in received_data.result:
		_handle_command(command)
	
func _handle_command(command: Dictionary):
	match command["cmd"]:
		"RoomInfo":
			ModLoaderLog.debug("Received RoomInfo cmd.", LOG_NAME)
			if _connected_to_multiworld:
				ModLoaderLog.debug("Asked to connect to server when already connected. Ignoring", LOG_NAME)
			var connect_command = {
					"cmd": "Connect", 
					"game": _game, 
					"name": _user,
					"password": _password,
					"uuid": "Godot",
					"version": {"major": 0,"minor": 4,"build": 2,"class": "Version"},
					"items_handling": 0b111,
					"tags": [],
					"slot_data": true
				}
			_send_command(connect_command)
			get_data_package(["Brotato", "Archipelago"])
		"ConnectionRefused":
			ModLoaderLog.debug("Received ConnectionRefused cmd.", LOG_NAME)
		"Connected":
			ModLoaderLog.debug("Received Connected cmd.", LOG_NAME)
		"ReceivedItems":
			ModLoaderLog.debug("Received ReceivedItems cmd.", LOG_NAME)
		"LocationInfo":
			ModLoaderLog.debug("Received LocationInfo cmd.", LOG_NAME)
		"RoomUpdate":
			ModLoaderLog.debug("Received RoomUpdate cmd.", LOG_NAME)
		"PrintJSON":
			ModLoaderLog.debug("Received PrintJSON cmd.", LOG_NAME)
		"DataPackage":
			ModLoaderLog.debug("Received DataPackage cmd.", LOG_NAME)
			emit_signal("on_data_package", command)
		"Bounced":
			ModLoaderLog.debug("Received Bounced cmd.", LOG_NAME)
		"InvalidPacket":
			ModLoaderLog.debug("Received InvalidPacket cmd.", LOG_NAME)
		"Retrieved":
			ModLoaderLog.debug("Received Retrieved cmd.", LOG_NAME)
		"SetReply":
			ModLoaderLog.debug("Received SetReply cmd.", LOG_NAME)
		_:
			ModLoaderLog.warning("Received Unknown Command %s" % command["cmd"], LOG_NAME)

func _process(_delta):
	_client.poll()
