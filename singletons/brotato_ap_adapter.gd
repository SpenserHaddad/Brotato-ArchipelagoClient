extends Node
class_name BrotatoApAdapter

const LOG_NAME = "RampagingHippy-Archipelago/Brotato Client"

onready var websocket_client: ApClientService

var constants: BrotatoApConstants
const game: String = "Brotato"
export var player: String
export var password: String

var _item_name_to_id: Dictionary
var _item_id_to_name: Dictionary
var _location_name_to_id: Dictionary
var _location_id_to_name: Dictionary

var _num_consumables_found = 0

var game_data = ApGameData.new()

class ApGameData:
	var starting_gold: int = 0
	var starting_xp : int = 0
	var received_characters: Array = []

# Item received signals
signal character_received
signal xp_received
signal gold_received
signal item_received

func _init(websocket_client_: ApClientService):
	constants = load("res://mods-unpacked/RampagingHippy-Archipelago/singletons/constants.gd").new()
	self.websocket_client = websocket_client_
	websocket_client.connect("connection_state_changed", self, "_on_connection_state_changed")
	ModLoaderLog.debug("Brotato AP adapter initialized", LOG_NAME)

func _ready():
	var _status: int
	_status = websocket_client.connect("on_room_info", self, "_on_room_info")
	_status = websocket_client.connect("on_connected", self, "_on_ws_connected")
	_status = websocket_client.connect("on_data_package", self, "_on_data_package")
	_status = websocket_client.connect("on_received_items", self, "_on_received_items")

func _on_connection_state_changed(new_state: int):
	if new_state == ApClientService.State.STATE_CLOSED:
		# Reset game data to get a clean slate in case we reconnect
		ModLoaderLog.debug("Disconnected, clearing any game state.", LOG_NAME)
		game_data = ApGameData.new()

func connected_to_multiworld() -> bool:
	# Convenience method to check if connected to AP, so other scenes don't need to 
	# reference the WS client just to check this.
	return websocket_client.connected_to_multiworld()

func item_picked_up():
	var location_name = "Crate Drop %d" % _num_consumables_found
	_num_consumables_found += 1
	var location_id = _location_name_to_id[location_name]
	websocket_client.send_location_checks([location_id])


# WebSocket Command received handlers

func _on_room_info(room_info):
	websocket_client.get_data_package(["Brotato"])

func _on_ws_connected(command):
	return
	websocket_client.send_sync()

func _on_received_items(command):
	var items = command["items"]
	for item in items:
		var item_name = _item_id_to_name[item["item"]]
		ModLoaderLog.debug("Received item %s." % item_name, LOG_NAME)
		if constants.CHARACTERS.has(item_name):
			game_data.received_characters.append(item_name)
			emit_signal("character_received", item_name)
		elif item_name in constants.XP_ITEM_NAME_TO_VALUE:
			var xp_value = constants.XP_ITEM_NAME_TO_VALUE[item_name]
			game_data.starting_xp += xp_value
			ModLoaderLog.debug("Starting XP is now %d." % game_data.starting_xp, LOG_NAME)
			emit_signal("xp_received", xp_value)
		elif item_name in constants.GOLD_DROP_NAME_TO_VALUE:
			var gold_value = constants.GOLD_DROP_NAME_TO_VALUE[item_name]
			game_data.starting_gold += gold_value
			ModLoaderLog.debug("Starting gold is now %d." % game_data.starting_gold, LOG_NAME)
			emit_signal("gold_received", gold_value)

func _on_data_package(received_data_package):
	ModLoaderLog.debug("Got the data package", LOG_NAME)
	var data_package = received_data_package["data"]["games"][game]
	# ModLoaderLog.debug_json_print("Brotato data package:", data_package, LOG_NAME)
	_item_name_to_id = data_package["item_name_to_id"]
	_item_id_to_name = Dictionary()
	for item_name in _item_name_to_id:
		var item_id = _item_name_to_id[item_name]
		_item_id_to_name[item_id] = item_name
		
	_location_name_to_id = data_package["location_name_to_id"]
	_location_id_to_name = Dictionary()
	for location_name in _location_name_to_id:
		var location_id = _location_name_to_id[location_name]
		_location_id_to_name[location_id] = location_name

	websocket_client.send_connect(game, player, password)
