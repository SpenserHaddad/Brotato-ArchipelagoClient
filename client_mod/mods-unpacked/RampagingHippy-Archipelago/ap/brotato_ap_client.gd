extends GodotApClient
class_name BrotatoApClient

const _LOG_NAME = "RampagingHippy-Archipelago/Brotato Client"

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

func _init(websocket_client).(websocket_client):
	self.game = "Brotato"
	game_state = ApBrotatoGameState.new(self)
	character_progress = ApCharacterProgress.new(self, game_state)
	shop_slots_progress = ApShopSlotsProgress.new(self, game_state)
	gold_progress = ApGoldProgress.new(self, game_state)
	xp_progress = ApXpProgress.new(self, game_state)
	items_progress = ApItemsProgress.new(self, game_state)
	upgrades_progress = ApUpgradesProgress.new(self, game_state)
	common_loot_crate_progress = ApLootCrateProgress.new(self, game_state, "common")
	legendary_loot_crate_progress = ApLootCrateProgress.new(self, game_state, "legendary")
	waves_progress = ApWavesProgress.new(self, game_state)
	wins_progress = ApWinsProgress.new(self, game_state)

	ModLoaderLog.debug("Brotato AP adapter initialized", _LOG_NAME)

func connected_to_multiworld() -> bool:
	# Convenience method to check if connected to AP, so other scenes don't need to 
	# reference the player session just to check this.
	return self.connect_state == self.ConnectState.CONNECTED_TO_MULTIWORLD