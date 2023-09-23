extends Node
class_name BrotatoApAdapter

const LOG_NAME = "RampagingHippy-Archipelago/Brotato Client"

onready var websocket_client: ApClientService

var constants: BrotatoApConstants
const GAME: String = "Brotato"
const DataPackage = preload("./data_package.gd")
export var player: String
export var password: String

var game_data = ApGameData.new()

class ApCharacterProgress:
	var won_run: bool = false
	var waves_with_checks: Array = []

class ApGameData:
	var starting_gold: int = 0
	var starting_xp : int = 0
	var received_characters: Array = []
	var next_consumable_drop: int = 1
	var next_legendary_consumable_drop: int = 1

	# These will be updated in when we get the "Connected" message from the server
	var total_consumable_drops: int = 0
	var total_legendary_consumable_drops: int = 0

	var character_progress: Dictionary = {}

	func _init():
		for character in BrotatoApConstants.CHARACTERS:
			character_progress[character] = ApCharacterProgress.new()

var _data_package: DataPackage.BrotatoDataPackage

# Item received signals
signal character_received
signal xp_received
signal gold_received
signal item_received

func _init(websocket_client_: ApClientService):
	constants = load("res://mods-unpacked/RampagingHippy-Archipelago/singletons/constants.gd").new()
	self.websocket_client = websocket_client_
	var _success = websocket_client.connect("connection_state_changed", self, "_on_connection_state_changed")
	ModLoaderLog.debug("Brotato AP adapter initialized", LOG_NAME)

func _ready():
	var _status: int
	_status = websocket_client.connect("on_room_info", self, "_on_room_info")
	_status = websocket_client.connect("on_connected", self, "_on_connected")
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

# API for other scenes to query game state to update the game
func can_drop_consumable() -> bool:
	return game_data.next_consumable_drop <= game_data.total_consumable_drops

func can_drop_legendary_consumable() -> bool:
	return game_data.next_legendary_consumable_drop <= game_data.total_legendary_consumable_drops

# Hooks for other scenes to tell us that they got a check.
func consumable_picked_up():
	## Notify the client that the player has picked up an AP consumable.
	##
	## Sends the next "Crate Drop" check to the server.
	var location_name = "Crate Drop %d" % game_data.next_consumable_drop
	game_data.next_consumable_drop += 1
	var location_id = _data_package.location_name_to_id[location_name]
	websocket_client.send_location_checks([location_id])

func legendary_consumable_picked_up():
	## Notify the client that the player has picked up an AP legendary consumable.
	##
	## Sends the next "Legendary Crate Drop" check to the server.
	var location_name = "Legendary Crate Drop %d" % game_data.next_legendary_consumable_drop
	game_data.next_legendary_consumable_drop += 1
	var location_id = _data_package.location_name_to_id[location_name]
	websocket_client.send_location_checks([location_id])


func wave_won(character_id: String, wave_number: int):
	## Notify the client that the player won a wave with a particular character.
	##
	## If the player hasn't won the wave run with that character before, then the
	## corresponding location check will be sent to the server.
	var character_name = _character_id_to_name(character_id)
	if game_data.character_progress[character_name].waves_with_checks.has(wave_number):
		var location_name = "Wave %d Complete (%s)" % [wave_number, character_name]
		var location_id = _data_package.location_name_to_id[location_name]
		websocket_client.send_location_checks([location_id])

func run_won(character_id: String):
	## Notify the client that the player won a run with a particular character.
	##
	## If the player hasn't won a run with that character before, then the corresponding
	## location check will be sent to the server.
	var character_name = _character_id_to_name(character_id)
	if not game_data.character_progress[character_name].won_run:
		var location_name = "Run Complete (%s)" % character_name
		var location_id = _data_package.location_name_to_id[location_name]
		websocket_client.send_location_checks([location_id])

func _character_id_to_name(character_id: String) -> String:
	return character_id.trim_prefix("character_").capitalize()

# WebSocket Command received handlers
func _on_room_info(_room_info):
	websocket_client.get_data_package(["Brotato"])

func _on_connected(command):
	var start_time = Time.get_ticks_msec()
	var location_groups: DataPackage.BrotatoLocationGroups = _data_package.location_groups
	# Look through the checked locations to find our progress
	for location_id in command["checked_locations"]:
		var consumable_number = location_groups.consumables.get(location_id)
		if consumable_number:
			game_data.next_consumable_drop = max(game_data.next_consumable_drop, consumable_number)
			continue

		var legendary_consumable_number = location_groups.legendary_consumables.get(location_id)
		if legendary_consumable_number:
			game_data.next_legendary_consumable_drop = max(game_data.next_legendary_consumable_drop, legendary_consumable_number)
			continue

		var character_run_complete = location_groups.character_run_complete.get(location_id)
		if character_run_complete:
			game_data.character_progress[character_run_complete].won_run = true
			continue

	for location_id in command["missing_locations"]:
		var consumable_number = location_groups.consumables.get(location_id)
		if consumable_number:
			game_data.total_consumable_drops = max(game_data.total_consumable_drops, consumable_number)
			continue

		var legendary_consumable_number = location_groups.consumables.get(location_id)
		if legendary_consumable_number:
			game_data.total_legendary_consumable_drops = max(game_data.total_legendary_consumable_drops, legendary_consumable_number)
			continue

		var character_wave_complete = location_groups.character_wave_complete.get(location_id)
		if character_wave_complete:
			var wave_number = character_wave_complete[0]
			var wave_complete_character = character_wave_complete[1]
			game_data.character_progress[wave_complete_character].waves_with_checks.append(wave_number)
			continue
	var end_time = Time.get_ticks_msec()
	var elapsed = (end_time - start_time) / 1000
	ModLoaderLog.debug("Handled connected in %f s." % elapsed, LOG_NAME)

func _on_received_items(command):
	var items = command["items"]
	for item in items:
		var item_name = _data_package.item_id_to_name[item["item"]]
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
		else:
			ModLoaderLog.warning("No handler for item defined: %s." % item_name, LOG_NAME)

func _on_data_package(received_data_package):
	ModLoaderLog.debug("Got the data package", LOG_NAME)
	var data_package_info = received_data_package["data"]["games"][GAME]
	_data_package = DataPackage.BrotatoDataPackage.from_data_package(data_package_info)
	websocket_client.send_connect(GAME, player, password)
