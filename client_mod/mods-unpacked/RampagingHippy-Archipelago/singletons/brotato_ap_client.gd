extends Node
class_name BrotatoApClient

const LOG_NAME = "RampagingHippy-Archipelago/Brotato Client"
const GAME: String = "Brotato"

var ap_client
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

func _init(ap_client_):
	ap_client = ap_client_
	game_state = ApBrotatoGameInfo.new(ap_client)
	character_progress = ApCharacterProgress.new(ap_client, game_state)
	shop_slots_progress = ApShopSlotsProgress.new(ap_client, game_state)
	gold_progress = ApGoldProgress.new(ap_client, game_state)
	xp_progress = ApXpProgress.new(ap_client, game_state)
	items_progress = ApItemsProgress.new(ap_client, game_state)
	upgrades_progress = ApUpgradesProgress.new(ap_client, game_state)
	common_loot_crate_progress = ApLootCrateProgress.new(ap_client, game_state, "common")
	legendary_loot_crate_progress = ApLootCrateProgress.new(ap_client, game_state, "legendary")
	waves_progress = ApWavesProgress.new(ap_client, game_state)
	wins_progress = ApWinsProgress.new(ap_client, game_state)

	ModLoaderLog.debug("Brotato AP adapter initialized", LOG_NAME)

func connected_to_multiworld() -> bool:
	# Convenience method to check if connected to AP, so other scenes don't need to 
	# reference the player session just to check this.
	return ap_client.connect_state == ap_client.ConnectState.CONNECTED_TO_MULTIWORLD
