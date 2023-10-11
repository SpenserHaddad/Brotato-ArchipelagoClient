extends Node
class_name BrotatoApAdapter

const LOG_NAME = "RampagingHippy-Archipelago/Brotato Client"

onready var websocket_client

const constants_namespace = preload("res://mods-unpacked/RampagingHippy-Archipelago/singletons/constants.gd")
var constants
const GAME: String = "Brotato"
const DataPackage = preload("./data_package.gd")
export var player: String
export var password: String

var game_data = ApGameData.new()
var run_data = ApRunData.new()
var wave_data = ApWaveData.new()

class ApCharacterProgress:
	var won_run: bool = false
	var waves_with_checks: Dictionary = {}

class ApGameData:
	var goal_completed: bool = false
	var starting_gold: int = 0
	var starting_xp : int = 0
	var num_starting_shop_slots: int = 4
	var num_received_shop_slots: int = 0
	var received_items_by_tier: Dictionary = {
		Tier.COMMON: 0,
		Tier.UNCOMMON: 0,
		Tier.RARE: 0,
		Tier.LEGENDARY: 0
	}
	var received_upgrades_by_tier: Dictionary = {
		Tier.COMMON: 0,
		Tier.UNCOMMON: 0,
		Tier.RARE: 0,
		Tier.LEGENDARY: 0
	}

	var received_characters: Dictionary = {}
	var num_consumables_picked_up: int = 0
	var num_legendary_consumables_picked_up: int = 0

	# These will be updated in when we get the "Connected" message from the server
	var total_consumable_drops: int = 0
	var total_legendary_consumable_drops: int = 0

	var character_progress: Dictionary = {}
	var num_required_wins: int = 1
	var num_wins: int = 0

	func _init():
		for character in constants_namespace.new().CHARACTER_NAME_TO_ID:
			character_progress[character] = ApCharacterProgress.new()
			received_characters[character] = false

class ApRunData:
	var gift_item_count_by_tier: Dictionary = {
		Tier.COMMON: 0,
		Tier.UNCOMMON: 0,
		Tier.RARE: 0,
		Tier.LEGENDARY: 0
	}

class ApWaveData:
	# Keep track of how many AP items were dropped each wave but haven't been picked up,
	# and therefore their locations have not been sent. This helps us to not drop more
	# AP items than there are locations for.
	var ap_consumables_not_picked_up = 0
	var ap_legendary_consumables_not_picked_up = 0

var _data_package: DataPackage.BrotatoDataPackage

# Item received signals
signal character_received(character)
signal xp_received(xp_amount)
signal gold_received(gold_amount)
signal item_received(item_tier)
signal upgrade_received(upgrade_tier)
signal shop_slot_received(total_slots)
signal crate_drop_status_changed(can_drop_ap_consumables)
signal legendary_crate_drop_status_changed(can_drop_ap_legendary_consumables)

# Connection issue signals
signal on_connection_refused(reasons)

func _init(websocket_client_):
	constants = constants_namespace.new()
	self.websocket_client = websocket_client_
	var _success = websocket_client.connect("connection_state_changed", self, "_on_connection_state_changed")
	ModLoaderLog.debug("Brotato AP adapter initialized", LOG_NAME)

func _ready():
	var _status: int
	_status = websocket_client.connect("on_room_info", self, "_on_room_info")
	_status = websocket_client.connect("on_connected", self, "_on_connected")
	_status = websocket_client.connect("on_data_package", self, "_on_data_package")
	_status = websocket_client.connect("on_received_items", self, "_on_received_items")
	_status = websocket_client.connect("on_connection_refused", self, "_on_connection_refused")

func _on_connection_state_changed(new_state: int):\
	# ApClientService.State.STATE_CLOSED, can't use directly because of dynamic imports
	if new_state == 3:
		# Reset game data to get a clean slate in case we reconnect
		ModLoaderLog.debug("Disconnected, clearing any game state.", LOG_NAME)
		game_data = ApGameData.new()

func connected_to_multiworld() -> bool:
	# Convenience method to check if connected to AP, so other scenes don't need to 
	# reference the WS client just to check this.
	return websocket_client.connected_to_multiworld()

# Methods to check AP game state and send updates to the actual game.
func _update_can_drop_consumable():
	ModLoaderLog.debug(
					"Consumable drop status: picked up: %d, on ground: %d, total: %d." % 
					[game_data.num_consumables_picked_up, wave_data.ap_consumables_not_picked_up, game_data.total_consumable_drops],
					LOG_NAME)
	var can_drop = game_data.num_consumables_picked_up + wave_data.ap_consumables_not_picked_up < game_data.total_consumable_drops
	emit_signal("crate_drop_status_changed", can_drop)

func _update_can_drop_legendary_consumable():
	var can_drop = game_data.num_legendary_consumables_picked_up + wave_data.ap_legendary_consumables_not_picked_up < game_data.total_legendary_consumable_drops
	emit_signal("legendary_crate_drop_status_changed", can_drop)

# API for other scenes to query multiworld state
func get_num_shop_slots() -> int:
	return game_data.num_starting_shop_slots + game_data.num_received_shop_slots

# API for other scenes to tell us about in-game events.
func consumable_spawned():
	wave_data.ap_consumables_not_picked_up += 1
	ModLoaderLog.debug("Consumable spawned, number picked up now %d" % wave_data.ap_consumables_not_picked_up, LOG_NAME)	
	_update_can_drop_consumable()

func legendary_consumable_spawned():
	wave_data.ap_legendary_consumables_not_picked_up += 1
	_update_can_drop_legendary_consumable()

func consumable_picked_up():
	## Notify the client that the player has picked up an AP consumable.
	##
	## Sends the next "Crate Drop" check to the server.
	# TODO: Crate Drop to Loot Crate?
	game_data.num_consumables_picked_up += 1
	wave_data.ap_consumables_not_picked_up -= 1
	var location_name = "Loot Crate %d" % game_data.num_consumables_picked_up
	var location_id = _data_package.location_name_to_id[location_name]
	websocket_client.send_location_checks([location_id])
	ModLoaderLog.debug("Picked up crate %d, not picked up in wave is %d" % [game_data.num_consumables_picked_up, wave_data.ap_consumables_not_picked_up], LOG_NAME)	

func legendary_consumable_picked_up():
	## Notify the client that the player has picked up an AP legendary consumable.
	##
	## Sends the next "Legendary Crate Drop" check to the server.
	game_data.num_legendary_consumables_picked_up += 1
	wave_data.ap_legendary_consumables_not_picked_up -= 1
	var location_name = "Legendary Crate Drop %d" % game_data.num_legendary_consumables_picked_up
	var location_id = _data_package.location_name_to_id[location_name]
	websocket_client.send_location_checks([location_id])
	wave_data.ap_legendary_consumables_not_picked_up -= 1

func gift_item_processed(gift_tier: int) -> int:
	## Notify the client that a gift item is being processed.
	##
	## Gift items are items received from the multiworld. This should be called when
	## the consumables are processed at the end of the round for each item.
	## This increments the number of items of the input tier processed this run,
	## then returns the wave that the received item should be processed as.
	# TODO: 
	run_data.gift_item_count_by_tier[gift_tier] += 1
	return int(ceil(run_data.gift_item_count_by_tier[gift_tier] / constants.NUM_ITEM_DROPS_PER_WAVE)) % 20

func run_started():
	## Notify the client that a new run has started.
	##
	## To be called by main._ready() only, so we can reinitialize run-specific data.
	ModLoaderLog.debug("New run started with character %s" % RunData.current_character.name, LOG_NAME)
	run_data = ApRunData.new()

func wave_started():
	## Notify the client that a new wave has started.
	##
	## To be called by main._ready() only, so we can reinitialize wave-specific data.
	ModLoaderLog.debug("Wave %d started" % RunData.current_wave, LOG_NAME)
	wave_data = ApWaveData.new()
	# TODO: NECESSARY?
	_update_can_drop_consumable()
	_update_can_drop_legendary_consumable()

func wave_won(character_id: String, wave_number: int):
	## Notify the client that the player won a wave with a particular character.
	##
	## If the player hasn't won the wave run with that character before, then the
	## corresponding location check will be sent to the server.
	var character_name = constants.CHARACTER_ID_TO_NAME[character_id]
	if not game_data.character_progress[character_name].waves_with_checks.get(wave_number, true):
		var location_name = "Wave %d Completed (%s)" % [wave_number, character_name]
		var location_id = _data_package.location_name_to_id[location_name]
		websocket_client.send_location_checks([location_id])

func run_won(character_id: String):
	## Notify the client that the player won a run with a particular character.
	##
	## If the player hasn't won a run with that character before, then the corresponding
	## location check will be sent to the server.
	var character_name = constants.CHARACTER_ID_TO_NAME[character_id]
	if not game_data.character_progress[character_name].won_run:
		var location_name = "Run Won (%s)" % character_name
		var location_id = _data_package.location_name_to_id[location_name]
		
		var event_name = location_name
		var event_id = _data_package.location_name_to_id[event_name]
		websocket_client.send_location_checks([location_id, event_id])

func run_complete_received():
	self.game_data.num_wins += 1
	if self.game_data.num_wins >= self.game_data.num_required_wins and not self.game_data.goal_completed:
		self.game_data.goal_completed = true
		# 30 = ApClientService.ClientStatus.CLIENT_GOAL
		websocket_client.status_update(30)

# WebSocket Command received handlers
func _on_room_info(_room_info):
	websocket_client.get_data_package(["Brotato"])

func _on_connection_refused(command):
	var errors = command["errors"]
	var error_str = ", ".join(PoolStringArray(errors))
	ModLoaderLog.warning("Connection refused: %s" % error_str, LOG_NAME)
	emit_signal("on_connection_refused", errors)

func _on_connected(command):
	var location_groups: DataPackage.BrotatoLocationGroups = _data_package.location_groups

	# Get options and other info from the slot data
	var slot_data = command["slot_data"]
	game_data.total_consumable_drops = slot_data["num_consumables"]
	game_data.total_legendary_consumable_drops = slot_data["num_legendary_consumables"]
	game_data.num_required_wins = slot_data["num_wins_needed"]
	game_data.num_starting_shop_slots = slot_data["num_starting_shop_slots"]
	var waves_with_checks: Array = slot_data["waves_with_checks"]
	for character in constants.CHARACTER_NAME_TO_ID:
		for wave in waves_with_checks:
			game_data.character_progress[character].waves_with_checks[int(wave)] = false

	# Look through the checked locations to find some additonal progress
	for location_id in command["checked_locations"]:
		var consumable_number = location_groups.consumables.get(location_id)
		if consumable_number:
			game_data.num_consumables_picked_up = max(game_data.num_consumables_picked_up, consumable_number)
			continue

		var legendary_consumable_number = location_groups.legendary_consumables.get(location_id)
		if legendary_consumable_number:
			game_data.num_legendary_consumables_picked_up = max(game_data.num_legendary_consumables_picked_up, legendary_consumable_number)
			continue

		var character_run_complete = location_groups.character_run_complete.get(location_id)
		if character_run_complete:
			game_data.character_progress[character_run_complete].won_run = true
			continue
		
		var character_wave_complete = location_groups.character_wave_complete.get(location_id)
		if character_wave_complete:
			var wave_number = character_wave_complete[0]
			var wave_character = character_wave_complete[1]
			game_data.character_progress[wave_character].waves_with_checks[wave_number] = true
		
func _on_received_items(command):
	var items = command["items"]
	for item in items:
		var item_name: String = _data_package.item_id_to_name[item["item"]]
		ModLoaderLog.debug("Received item %s." % item_name, LOG_NAME)
		if constants.CHARACTER_NAME_TO_ID.has(item_name):
			game_data.received_characters[item_name] = true
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
		elif item_name in constants.ITEM_DROP_NAME_TO_TIER:
			var item_tier = constants.ITEM_DROP_NAME_TO_TIER[item_name]
			game_data.received_items_by_tier[item_tier] += 1
			ModLoaderLog.debug("Got item Tier %d" % item_tier, LOG_NAME)
			emit_signal("item_received", item_tier)
		elif item_name in constants.UPGRADE_NAME_TO_TIER:
			var upgrade_tier = constants.UPGRADE_NAME_TO_TIER[item_name]
			game_data.received_upgrades_by_tier[upgrade_tier] += 1
			ModLoaderLog.debug("Got upgrade Tier %d" % upgrade_tier, LOG_NAME)
			emit_signal("upgrade_received", upgrade_tier)
		elif item_name == constants.SHOP_SLOT_ITEM_NAME:
			game_data.num_received_shop_slots += 1
			var total_shop_slots = get_num_shop_slots()
			ModLoaderLog.debug("Recieved shop slot. Total is now %d" % total_shop_slots, LOG_NAME)
			emit_signal("shop_slot_received", total_shop_slots)
		elif item_name == "Run Won":
			run_complete_received()
		else:
			ModLoaderLog.warning("No handler for item defined: %s." % item_name, LOG_NAME)

func _on_data_package(received_data_package):
	ModLoaderLog.debug("Got the data package", LOG_NAME)
	var data_package_info = received_data_package["data"]["games"][GAME]
	_data_package = DataPackage.BrotatoDataPackage.from_data_package(data_package_info)
	websocket_client.send_connect(GAME, player, password)
