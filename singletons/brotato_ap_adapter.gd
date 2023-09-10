extends Node
class_name BrotatoApAdapter

onready var websocket_client: ApClientService
var data_package

var _num_consumables_found = 0

func _init(websocket_client_: ApClientService):
	self.websocket_client = websocket_client_
	ModLoaderLog.debug("Brotato AP adapter initialized", "RampagingHippy-Archipelago")

func _ready():
	websocket_client.connect("on_data_package", self, "_check_data_package")

func item_picked_up(item: Node, tier: Tier, character: String = ""):
	_num_consumables_found += 1
	var location_name = "Common Pickup %d" % _num_consumables_found
	var location_id = data_package["location_name_to_id"][location_name]
	websocket_client.send_location_checks([location_id])


func _check_data_package(received_data_package):
	ModLoaderLog.debug("Got the data package", "RampagingHippy-Archipelago")
	data_package = received_data_package["data"]["games"]["Brotato"]
	ModLoaderLog.debug_json_print("Brotato data package:", data_package, "RampagingHippy-Archipelago")
