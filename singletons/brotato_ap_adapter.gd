extends Node
class_name BrotatoApAdapter

const LOG_NAME = "RampagingHippy-Archipelago: Brotato Client"

onready var websocket_client: ApClientService

const game: String = "Brotato"
export var player: String
export var password: String

var _item_name_to_id: Dictionary
var _location_name_to_id: Dictionary
var _item_id_to_name: Dictionary
var _location_id_to_name: Dictionary

var _num_consumables_found = 0

func _init(websocket_client_: ApClientService):
	self.websocket_client = websocket_client_
	ModLoaderLog.debug("Brotato AP adapter initialized", LOG_NAME)

func _ready():
	var _status: int
	_status = websocket_client.connect("on_room_info", self, "_on_room_info")
	_status = websocket_client.connect("on_connected", self, "_on_ws_connected")
	_status = websocket_client.connect("on_data_package", self, "_on_data_package")
	_status = websocket_client.connect("on_received_items", self, "_on_received_items")

func connected_to_multiworld() -> bool:
	# Convenience method to check if connected to AP, so other scenes don't need to 
	# reference the WS client just to check this.
	return websocket_client.connected_to_multiworld()


func item_picked_up(item: Node, tier: Tier):
	_num_consumables_found += 1
	var location_name = "Common Pickup %d" % _num_consumables_found
	var location_id = _location_name_to_id[location_name]
	websocket_client.send_location_checks([location_id])


# WebSocket Command received handlers

func _on_room_info(room_info):
	# ModLoaderLog.debug_json_print("Got the room info", room_info, LOG_NAME)
	websocket_client.get_data_package(["Brotato"])

func _on_ws_connected(command):
	self.websocket_client.send_sync()

func _on_received_items(command):
	var items = command["items"]
	for item in items:
		var item_name = _item_id_to_name[item["item"]]
		ModLoaderLog.debug_json_print("Received item %s:" % item_name, item, LOG_NAME)

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
