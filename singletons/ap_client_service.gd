extends Node
class_name ApClientService
const LOG_NAME = "AP Client"

var _client = WebSocketClient.new()
var _peer: WebSocketPeer
var _game: String
var _user: String
var _password: String

var _connected_to_multiworld = false

signal item_received

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

func connect_to_multiworld(server: String, port: int, user: String, password: String = ""):
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

func _closed(was_clean = false):
	ModLoaderLog.info("AP connection closed, clean: %s" % was_clean, LOG_NAME)
	set_process(false)

func _connected(proto = ""):
	ModLoaderLog.info("AP connection opened with protocol: %s" % proto, LOG_NAME)

func _on_data():
	var received_data_str = _peer.get_packet().get_string_from_utf8()
	var received_data = JSON.parse(received_data_str)
	ModLoaderLog.debug("Got data from server: %s" % received_data_str, LOG_NAME)
	for command in received_data.result:
		_handle_command(command)
	
func _handle_command(command: Dictionary):
	match command["cmd"]:
		"RoomInfo":
			ModLoaderLog.debug("Received RoomInfo cmd.", LOG_NAME)
			if _connected_to_multiworld:
				ModLoaderLog.debug("Asked to connect to server when already connected. Ignoring", LOG_NAME)
			var connect_command = [
				{
					"cmd": "Connect", 
					"game": _game, 
					"name": _user,
					"password": _password,
					"uuid": "Godot",
					"version": {"major": 0,"minor": 4,"build": 2,"class": "Version"},
					"items_handling": 0b111,
					"tags": [],
					"slot_data": true
				}]
			var connect_command_str = JSON.print(connect_command)
			var _result = _peer.put_packet(connect_command_str.to_ascii())
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	_client.poll()
