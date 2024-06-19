extends ApPlayerSession
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
	character_progress = ApCharacterProgress.new(ap_session, game_state)
	shop_slots_progress = ApShopSlotsProgress.new(ap_session, game_state)
	gold_progress = ApGoldProgress.new(ap_session, game_state)
	xp_progress = ApXpProgress.new(ap_session, game_state)
	items_progress = ApItemsProgress.new(ap_session, game_state)
	upgrades_progress = ApUpgradesProgress.new(ap_session, game_state)
	common_loot_crate_progress = ApLootCrateProgress.new(ap_session, game_state, "common")
	legendary_loot_crate_progress = ApLootCrateProgress.new(ap_session, game_state, "legendary")
	waves_progress = ApWavesProgress.new(ap_session, game_state)
	wins_progress = ApWinsProgress.new(ap_session, game_state)

	ModLoaderLog.debug("Brotato AP adapter initialized", LOG_NAME)

func connected_to_multiworld() -> bool:
	# Convenience method to check if connected to AP, so other scenes don't need to 
	# reference the player session just to check this.
	return ap_session.connect_state == ap_session.ConnectState.CONNECTED_TO_MULTIWORLD
