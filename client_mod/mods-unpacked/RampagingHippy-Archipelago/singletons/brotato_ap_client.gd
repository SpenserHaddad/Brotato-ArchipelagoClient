extends Node
class_name BrotatoApClient

const LOG_NAME = "RampagingHippy-Archipelago/Brotato Client"

const _constants_namespace = preload ("./constants.gd")
const _game_state_namespace = preload ("../progress/game_state.gd")
const DataPackage = preload ("./data_package.gd")
const _AP_TYPES = preload ("./ap_types.gd")
const GAME: String = "Brotato"

onready var ap_session: ApPlayerSession

var constants = _constants_namespace.new()
var game_state: ApGameState
var _received_gold_data_storage_key: String = ""
var _received_xp_data_storage_key: String = ""
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

func _init(ap_session_: ApPlayerSession):
	self.ap_session = ap_session_
	ModLoaderLog.debug("Brotato AP adapter initialized", LOG_NAME)

func _ready():
	var _status: int
	_status = ap_session.connect("connection_state_changed", self, "_on_connection_state_changed")
	_status = ap_session.connect("item_received", self, "_on_item_received")
	_status = ap_session.connect("data_storage_updated", self, "_on_data_storage_updated")
	ModLoaderLog.debug("Loaded AP client. %d" % _status, LOG_NAME)

func connected_to_multiworld() -> bool:
	# Convenience method to check if connected to AP, so other scenes don't need to 
	# reference the player session just to check this.
	return ap_session.connect_state == ApPlayerSession.ConnectState.CONNECTED_TO_MULTIWORLD

# Methods to check AP game state and send updates to the actual game.
func _update_can_drop_consumable():
	ModLoaderLog.debug(
					"Consumable drop status: picked up: %d, on ground: %d, total: %d." %
					[
						game_state.num_consumables_picked_up,
						game_state.run_state.ap_consumables_not_picked_up,
						game_state.total_consumable_drops
					],
					LOG_NAME)
	var can_drop = (
		connected_to_multiworld()
		and game_state.num_existing_consumables() < game_state.total_consumable_drops
	)
	emit_signal("crate_drop_status_changed", can_drop)

func _update_can_drop_legendary_consumable():
	var can_drop = (
		connected_to_multiworld()
		and game_state.num_existing_legendary_consumables() < game_state.total_legendary_consumable_drops
	)
	emit_signal("legendary_crate_drop_status_changed", can_drop)

func _give_player_unreceived_ap_gold_and_xp():
	## Give the player any gold and XP they've received but haven't "picked up" yet.
	##
	## We want to give the player any gold and XP items once in either their current run
	## or the run after the one they receive the items, to keep them from getting too
	## strong too fast.
	##
	## So, if this is called while the player is in a run, the method will give them any
	## gold/XP they've gotten from items that haven't been claimed yet. We then update
	## two Archipelago data storage keys with the total amount of each they've been
	## given so the tracked value persists between multiple runs of the game. We already
	## track the total received (both given and not) from items as part of the "items
	## received" handler.

	if not game_state.run_active:
		return
	var gold_to_give = game_state.gold_received_from_multiworld - game_state.gold_given_to_player
	if gold_to_give > 0:
		ModLoaderLog.info("Giving player %d gold" % gold_to_give, LOG_NAME)
		RunData.add_gold(gold_to_give)
		ap_session.set_value(
			_received_gold_data_storage_key,
			ApTypes.DataStorageOperationType.ADD,
			gold_to_give,
			0,
			true
		)
	else:
		ModLoaderLog.debug("Not giving player gold. Received is %d and given is %d." % [game_state.gold_received_from_multiworld, game_state.gold_given_to_player], LOG_NAME)

	var xp_to_give = game_state.xp_received_from_multiworld - game_state.xp_given_to_player
	if xp_to_give > 0:
		ModLoaderLog.info("Giving player %d XP" % xp_to_give, LOG_NAME)
		RunData.add_xp(xp_to_give)
		ap_session.set_value(
			_received_xp_data_storage_key,
			ApTypes.DataStorageOperationType.ADD,
			xp_to_give,
			0,
			true
		)
	else:
		ModLoaderLog.debug("Not giving player XP. Received is %d and given is %d." % [game_state.xp_received_from_multiworld, game_state.xp_given_to_player], LOG_NAME)

# API for other scenes to query multiworld state
func get_num_shop_slots() -> int:
		return game_state.num_shop_slots()

# API for other scenes to tell us about in-game events.
func consumable_spawned():
	game_state.consumable_spawned()
	_update_can_drop_consumable()

func legendary_consumable_spawned():
	game_state.legendary_consumable_spawned()
	_update_can_drop_legendary_consumable()

func consumable_picked_up():
	## Handler for when player picks up an AP consumable.
	##
	## Sends the next "Crate Drop" check to the server, and updates the local
	## state with the total number of consumables picked up and the number on the
	## ground.
	game_state.consumable_picked_up()
	var location_name = "Loot Crate %d" % game_state.num_consumables_picked_up
	var location_id = ap_session.data_package.location_name_to_id[location_name]
	ap_session.check_location(location_id)
	ModLoaderLog.debug("Picked up crate %d, not picked up in wave is %d" % [game_state.num_consumables_picked_up, game_state.run_state.ap_consumables_not_picked_up], LOG_NAME)

func legendary_consumable_picked_up():
	## Handler for when player picks up an AP legendary consumable.
	##
	## Sends the next "Legendary Crate Drop" check to the server, and updates the local
	## state with the total number of legendary consumables picked up and the number on
	## the ground.
	game_state.legendary_consumable_picked_up()
	var location_name = "Legendary Loot Crate %d" % game_state.num_legendary_consumables_picked_up
	var location_id = ap_session.data_package.location_name_to_id[location_name]
	ap_session.check_location(location_id)

func gift_item_processed(gift_tier: int) -> int:
	## Notify the client that a gift item is being processed.
	##
	## Gift items are items received from the multiworld. This should be called when
	## the consumables are processed at the end of the round for each item.
	## This increments the number of items of the input tier processed this run,
	## then returns the wave that the received item should be processed as.
	game_state.run_state.gift_item_count_by_tier[gift_tier] += 1
	# 20 being the total number of waves.
	return int(ceil(game_state.run_state.gift_item_count_by_tier[gift_tier] / constants.NUM_ITEM_DROPS_PER_WAVE)) % 20

func run_started():
	## Notify the client that a new run has started.
	##
	## To be called by main._ready() only, so we can reinitialize run-specific data.
	ModLoaderLog.debug("New run started with character %s." % RunData.current_character.name, LOG_NAME)
	game_state.run_started()
	game_state.run_active = true
	_give_player_unreceived_ap_gold_and_xp()

func run_finished():
	## Notify the client that the current run has finished
	ModLoaderLog.debug("Run finished with character %s." % RunData.current_character.name, LOG_NAME)
	game_state.run_active = false

func wave_started():
	## Notify the client that a new wave has started.
	##
	## To be called by main._ready() only, so we can reinitialize wave-specific data.
	ModLoaderLog.debug("Wave %d started" % RunData.current_wave, LOG_NAME)
	game_state.wave_started()
	# TODO: NECESSARY?
	_update_can_drop_consumable()
	_update_can_drop_legendary_consumable()

func wave_won(character_id: String, wave_number: int):
	## Notify the client that the player won a wave with a particular character.
	##
	## If the player hasn't won the wave run with that character before, then the
	## corresponding location check will be sent to the server.
	var character_name = constants.CHARACTER_ID_TO_NAME[character_id]
	if not game_state.character_progress[character_name].reached_check_wave.get(wave_number, true):
		var location_name = "Wave %d Completed (%s)" % [wave_number, character_name]
		var location_id = ap_session.data_package.location_name_to_id[location_name]
		ap_session.check_location(location_id)

func run_won(character_id: String):
	## Notify the client that the player won a run with a particular character.
	##
	## If the player hasn't won a run with that character before, then the corresponding
	## location check will be sent to the server.
	var character_name = constants.CHARACTER_ID_TO_NAME[character_id]
	if not game_state.character_progress[character_name].won_run:
		var location_name = "Run Won (%s)" % character_name
		var location_id = ap_session.data_package.location_name_to_id[location_name]
		
		var event_name = location_name
		var event_id = ap_session.data_package.location_name_to_id[event_name]
		ap_session.check_location(location_id)
		ap_session.check_location(event_id)

func run_complete_received():
	game_state.num_wins += 1
	if game_state.num_wins >= game_state.num_wins_needed and not game_state.goal_completed:
		game_state.goal_completed = true
		ap_session.set_status(_AP_TYPES.ClientStatus.CLIENT_GOAL)

func _on_connection_state_changed(new_state: int, _error: int=0):
	if new_state == ApPlayerSession.ConnectState.CONNECTED_TO_MULTIWORLD:
		_on_connected_to_multiworld()

func _on_connected_to_multiworld():
	
	# Ensure the data storage keys are initialized (i.e. first time connecting as slot)
	_received_gold_data_storage_key = "%s_received_gold" % ap_session.player
	_received_xp_data_storage_key = "%s_received_xp" % ap_session.player
	ap_session.set_value(_received_gold_data_storage_key, ApTypes.DataStorageOperationType.DEFAULT, 0, 0, false)
	ap_session.set_value(_received_xp_data_storage_key, ApTypes.DataStorageOperationType.DEFAULT, 0, 0, false)

	# Get the current value of the data storage entries (i.e. not first time connecting)
	ap_session.get_value([_received_gold_data_storage_key, _received_xp_data_storage_key])
	ap_session.set_notify([_received_gold_data_storage_key, _received_xp_data_storage_key])
	
	# Get options and other info from the slot data and data 
	var slot_data = ap_session.slot_data
	game_state = _game_state_namespace.new(
		slot_data["num_wins_needed"],
		slot_data["num_consumables"],
		slot_data["num_legendary_consumables"],
		slot_data["num_starting_shop_slots"],
		slot_data["waves_with_checks"]
	)

	var location_groups = DataPackage.BrotatoLocationGroups.from_location_table(ap_session.data_package.location_name_to_id)

	# Look through the checked locations to find some additonal progress
	for location_id in ap_session.checked_locations:
		var consumable_number = location_groups.consumables.get(location_id)
		if consumable_number != null and consumable_number > game_state.num_consumables_picked_up:
			game_state.num_consumables_picked_up = consumable_number
			continue

		var legendary_consumable_number = location_groups.legendary_consumables.get(location_id)
		if legendary_consumable_number != null and legendary_consumable_number > game_state.num_legendary_consumables_picked_up:
			game_state.num_legendary_consumables_picked_up = legendary_consumable_number
			continue

		var character_run_complete = location_groups.character_run_complete.get(location_id)
		if character_run_complete:
			game_state.character_progress[character_run_complete].won_run = true
			continue
		
		var character_wave_complete = location_groups.character_wave_complete.get(location_id)
		if character_wave_complete:
			var wave_number = character_wave_complete[0]
			var wave_character = character_wave_complete[1]
			game_state.character_progress[wave_character].reached_check_wave[wave_number] = true
		
func _on_item_received(item_name: String, _item: Dictionary):
	# NOTE: We used to have some debug logs in each if/elif branch to say what item(s)
	# we got, but for larger payloads, such as connecting to a completed game or when a
	# game is released/collected, the log commands caused a several-second slowdown when
	# combined. Add logs here only when debugging something, don't keep.
	if constants.CHARACTER_NAME_TO_ID.has(item_name):
		game_state.character_progress[item_name].unlocked = true
		emit_signal("character_received", item_name)
	elif item_name in constants.XP_ITEM_NAME_TO_VALUE:
		var xp_value = constants.XP_ITEM_NAME_TO_VALUE[item_name]
		game_state.xp_received_from_multiworld += xp_value
		_give_player_unreceived_ap_gold_and_xp()
		emit_signal("xp_received", xp_value)
	elif item_name in constants.GOLD_DROP_NAME_TO_VALUE:
		var gold_value = constants.GOLD_DROP_NAME_TO_VALUE[item_name]
		game_state.gold_received_from_multiworld += gold_value
		_give_player_unreceived_ap_gold_and_xp()
		emit_signal("gold_received", gold_value)
	elif item_name in constants.ITEM_DROP_NAME_TO_TIER:
		var item_tier = constants.ITEM_DROP_NAME_TO_TIER[item_name]
		game_state.received_items_by_tier[item_tier] += 1
		emit_signal("item_received", item_tier)
	elif item_name in constants.UPGRADE_NAME_TO_TIER:
		var upgrade_tier = constants.UPGRADE_NAME_TO_TIER[item_name]
		game_state.received_upgrades_by_tier[upgrade_tier] += 1
		emit_signal("upgrade_received", upgrade_tier)
	elif item_name == constants.SHOP_SLOT_ITEM_NAME:
		game_state.num_received_shop_slots += 1
		var total_shop_slots = get_num_shop_slots()
		emit_signal("shop_slot_received", total_shop_slots)
	elif item_name == "Run Won":
		run_complete_received()
	else:
		ModLoaderLog.warning("No handler for item defined: %s." % item_name, LOG_NAME)

func _on_data_storage_updated(key: String, new_value, _original_value=null):
	if key == _received_gold_data_storage_key:
		ModLoaderLog.debug(
			"Updating gold given to player from to %d. Total received is %d." %
			[new_value, game_state.gold_received_from_multiworld], LOG_NAME)
		game_state.gold_given_to_player = new_value
	elif key == _received_xp_data_storage_key:
		ModLoaderLog.debug(
			"Updating XP given to player from %d. Total received is %d." %
			[new_value, game_state.xp_received_from_multiworld], LOG_NAME
		)
		game_state.xp_given_to_player = new_value
