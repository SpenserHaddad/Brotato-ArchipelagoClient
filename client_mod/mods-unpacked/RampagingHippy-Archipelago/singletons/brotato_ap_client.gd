extends Node
class_name BrotatoApClient

const LOG_NAME = "RampagingHippy-Archipelago/Brotato Client"

const GAME: String = "Brotato"

onready var ap_session

var game_state

# New progress trackers
var character_progress
var shop_slots_progress
var gold_progress
var xp_progress
var items_progress
var upgrades_progress
var common_loot_crate_progress
var legendary_loot_crate_progress
var waves_progress
var wins_progress

# Connection issue signals
signal on_connection_refused(reasons)

func _init(ap_session_):
	ap_session = ap_session_
	game_state = ApBrotatoGameInfo.new(ap_session)
	character_progress = ApCharacterProgress.new(ap_session)
	shop_slots_progress = ApShopSlotsProgress.new(ap_session)
	gold_progress = ApGoldProgress.new(ap_session, game_state)
	xp_progress = ApXpProgress.new(ap_session, game_state)
	items_progress = ApItemsProgress.new(ap_session)
	upgrades_progress = ApUpgradesProgress.new(ap_session)
	common_loot_crate_progress = ApLootCrateProgress.new(ap_session, game_state, "common")
	legendary_loot_crate_progress = ApLootCrateProgress.new(ap_session, game_state, "legendary")
	waves_progress = ApWavesProgress.new(ap_session, game_state)
	wins_progress = ApWinsProgress.new(ap_session, game_state)

	ModLoaderLog.debug("Brotato AP adapter initialized", LOG_NAME)

func _ready():
	var _status: int
	# _status = ap_session.connect("connection_state_changed", self, "_on_connection_state_changed")
	# _status = ap_session.connect("item_received", self, "_on_item_received")
	# _status = ap_session.connect("data_storage_updated", self, "_on_data_storage_updated")
	ModLoaderLog.debug("Loaded AP client. %d" % _status, LOG_NAME)

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
