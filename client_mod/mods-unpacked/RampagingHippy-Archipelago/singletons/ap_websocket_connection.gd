extends Node
class_name ApWebSocketConnection
# Hard-code mod name to avoid cyclical dependency
var LOG_NAME = "RampagingHippy-Archipelago/AP Client"

# The client handles connecting to the server, and the peer handles sending/receiving
# data after connecting. We set the peer in the "_on_connection_established" callback,
# and clear it in the "_on_connection_closed" callback.
var _client = WebSocketClient.new()
var _peer: WebSocketPeer
var _url: String

enum State {
	STATE_CONNECTING = 0
	STATE_OPEN = 1
	STATE_CLOSING = 2
	STATE_CLOSED = 3
}
signal connection_state_changed

var connection_state = State.STATE_CLOSED

enum ClientStatus {
## This is the Client States enum as documented in AP->network protocol
CLIENT_UNKOWN = 0
CLIENT_CONNECTED = 5
CLIENT_READY = 10
CLIENT_PLAYING = 20
CLIENT_GOAL = 30
}

signal item_received
signal on_room_info
signal on_connected
signal on_connection_refused
signal on_received_items
signal on_location_info
signal on_room_update
signal on_print_json
signal on_data_package
signal on_bounced
signal on_invalid_packet
signal on_retrieved
signal on_set_reply

func _ready():
	# Connect base signals to get notified of connection open, close, and errors.
	_client.connect("connection_closed", self, "_on_connection_closed")
	_client.connect("connection_error", self, "_on_connection_error")
	_client.connect("connection_established", self, "_on_connection_established")
	_client.connect("data_received", self, "_on_data_received")
	# Increase max buffer size to accommodate larger payloads. The defaults are:
	#   - Max in/out buffer = 64 KB
	#   - Max in/out packets = 1024 
	# We increase the in buffer to 256 KB because some messages we receive are too large
	# for 64. The other defaults are fine though.
	_client.set_buffers(256, 1024, 64, 1024)
	
	# Always process so we don't disconnect if the game is paused for too long.
	pause_mode = Node.PAUSE_MODE_PROCESS
	
# Public API
func connect_to_multiworld(multiworld_url: String):
	if connection_state == State.STATE_OPEN:
		return
	_set_connection_state(State.STATE_CONNECTING)
	# Try to connect with SSL first. If this doesn't work then the _on_connection_error
	# callback will try again without SSL.
	_url = "wss://%s" % multiworld_url
	ModLoaderLog.info("Connecting to %s" % _url, LOG_NAME)
	var err = _client.connect_to_url(_url)
	if not err:
		# Start processing to poll the connection for data
		set_process(true)

func connected_to_multiworld() -> bool:
	return connection_state == State.STATE_OPEN
	
func disconnect_from_multiworld():
	if connection_state == State.STATE_CLOSED:
		return
	_set_connection_state(State.STATE_CLOSING)
	_client.disconnect_from_host()

func send_connect(game: String, user: String, password: String = "", slot_data: bool = true):
	_send_command({
		"cmd": "Connect", 
		"game": game, 
		"name": user,
		"password": password,
		"uuid": "Godot %s: %s" % [game, user], # TODO: What do we need here? We can't generate an actual UUID in 3.5
		"version": {"major": 0, "minor": 4, "build": 2, "class": "Version"},
		"items_handling": 0b111, # TODO: argument
		"tags": [],
		"slot_data": slot_data
	})

func send_sync():
	_send_command({"cmd": "Sync"})

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

func status_update(status: int):
	_send_command({
		"cmd": "StatusUpdate",
		"status": status,
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

# WebsocketClient callbacks
func _send_command(args: Dictionary):
	ModLoaderLog.info("Sending %s command" % args["cmd"], LOG_NAME)
	var command_str = JSON.print([args])
	var _result = _peer.put_packet(command_str.to_ascii())

func _on_connection_closed(was_clean = false):
	_set_connection_state(State.STATE_CLOSED)
	ModLoaderLog.info("AP connection closed, clean: %s" % was_clean, LOG_NAME)
	_peer = null
	set_process(false)

func _on_connection_established(_proto = ""):
	_set_connection_state(State.STATE_OPEN)
	_peer = _client.get_peer(1)
	_peer.set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	ModLoaderLog.info("Connected to multiworld %s." % _url, LOG_NAME)

func _on_connection_error():
	if _url.begins_with("wss://"):
		# We don't have any info on why the connection failed, so we assume it wsa
		# because the server doesn't support SSL. So, try connecting using "ws://"
		# instead.
		ModLoaderLog.debug("Connecting to multiworld %s failed, trying again using 'ws://'." % _url, LOG_NAME)
		_url = _url.replace("wss://", "ws://")
		_client.connect_to_url(_url)
	else:
		# Tried both options, error out now
		_set_connection_state(State.STATE_CLOSED)
		ModLoaderLog.info("Failed to connect to multiworld %s." % _url, LOG_NAME)

func _on_data_received():
	var received_data_str = _peer.get_packet().get_string_from_utf8()
	var received_data = JSON.parse(received_data_str)
	if received_data.result == null:
		ModLoaderLog.error("Failed to parse JSON for %s" % received_data_str, LOG_NAME)
		return
	for command in received_data.result:
		_handle_command(command)

# Internal plumbing
func _set_connection_state(state):
	ModLoaderLog.info("AP connection state changed to: %d" % state, LOG_NAME)
	connection_state = state
	emit_signal("connection_state_changed", connection_state)

func _handle_command(command: Dictionary):
	match command["cmd"]:
		"RoomInfo":
			ModLoaderLog.debug("Received RoomInfo cmd.", LOG_NAME)
			emit_signal("on_room_info", command)
		"ConnectionRefused":
			ModLoaderLog.debug("Received ConnectionRefused cmd.", LOG_NAME)
			emit_signal("on_connection_refused", command)
		"Connected":
			ModLoaderLog.debug("Received Connected cmd.", LOG_NAME)
			emit_signal("on_connected", command)
		"ReceivedItems":
			ModLoaderLog.debug("Received ReceivedItems cmd.", LOG_NAME)
			emit_signal("on_received_items", command)
		"LocationInfo":
			ModLoaderLog.debug("Received LocationInfo cmd.", LOG_NAME)
			emit_signal("on_location_info", command)
		"RoomUpdate":
			ModLoaderLog.debug("Received RoomUpdate cmd.", LOG_NAME)
			emit_signal("on_room_update", command)
		"PrintJSON":
			ModLoaderLog.debug("Received PrintJSON cmd.", LOG_NAME)
			emit_signal("on_print_json", command)
		"DataPackage":
			ModLoaderLog.debug("Received DataPackage cmd.", LOG_NAME)
			emit_signal("on_data_package", command)
		"Bounced":
			ModLoaderLog.debug("Received Bounced cmd.", LOG_NAME)
			emit_signal("on_bounced", command)
		"InvalidPacket":
			ModLoaderLog.debug("Received InvalidPacket cmd.", LOG_NAME)
			emit_signal("on_invalid_packet", command)
		"Retrieved":
			ModLoaderLog.debug("Received Retrieved cmd.", LOG_NAME)
			emit_signal("on_retrieved", command)
		"SetReply":
			ModLoaderLog.debug("Received SetReply cmd.", LOG_NAME)
			emit_signal("on_set_reply", command)
		_:
			ModLoaderLog.warning("Received Unknown Command %s" % command["cmd"], LOG_NAME)

func _process(_delta):
	# Only run when the connection the the server is not closed.
	_client.poll()
