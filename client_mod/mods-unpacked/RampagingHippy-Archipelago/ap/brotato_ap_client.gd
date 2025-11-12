extends "res://mods-unpacked/RampagingHippy-Archipelago/ap/godot_ap_client.gd"
class_name BrotatoApClient

const _LOG_NAME = "RampagingHippy-Archipelago/Brotato Client"

# "Import" classes for our attributes so we can create instances. The game doesn't know
# how to implicitly find our classes in non-dev builds, so we need to help it along.

# onready var <class_name> = preload(path...) doesn't seem to work with actual game.
var ApBrotatoGameState = load("res://mods-unpacked/RampagingHippy-Archipelago/ap/game_state.gd")
var ApCharacterProgress = load("res://mods-unpacked/RampagingHippy-Archipelago/progress/characters.gd")
var ApShopSlotsProgress = load("res://mods-unpacked/RampagingHippy-Archipelago/progress/shop_slots.gd")
var ApShopLockButtonsProgress = load("res://mods-unpacked/RampagingHippy-Archipelago/progress/shop_lock_buttons.gd")
var ApEnemyXpProgress = load("res://mods-unpacked/RampagingHippy-Archipelago/progress/enemy_xp.gd")
var ApGoldProgress = load("res://mods-unpacked/RampagingHippy-Archipelago/progress/gold.gd")
var ApXpProgress = load("res://mods-unpacked/RampagingHippy-Archipelago/progress/xp.gd")
var ApItemsProgress = load("res://mods-unpacked/RampagingHippy-Archipelago/progress/items.gd")
var ApUpgradesProgress = load("res://mods-unpacked/RampagingHippy-Archipelago/progress/upgrades.gd")
var ApLootCrateProgress = load("res://mods-unpacked/RampagingHippy-Archipelago/progress/loot_crates.gd")
var ApWavesProgress = load("res://mods-unpacked/RampagingHippy-Archipelago/progress/waves.gd")
var ApWinsProgress = load("res://mods-unpacked/RampagingHippy-Archipelago/progress/wins.gd")
var ApSavedRunsProgress = load("res://mods-unpacked/RampagingHippy-Archipelago/progress/saved_runs.gd")
var ApDeathLinkProgress = load("res://mods-unpacked/RampagingHippy-Archipelago/progress/deathlink.gd")
var GodotApClientDebugSettings = load("res://mods-unpacked/RampagingHippy-Archipelago/ap/debug.gd")

var game_state
var debug

# Progress trackers
var character_progress
var shop_slots_progress
var shop_lock_buttons_progress
var enemy_xp_progress
var gold_progress
var xp_progress
var items_progress
var upgrades_progress
var common_loot_crate_progress
var legendary_loot_crate_progress
var waves_progress
var wins_progress
var saved_runs_progress
var deathlink_progress

# Holder for all the trackers together so we can perform bulk operations.
var _progress_trackers: Array

signal on_connection_refused(reasons)

func _init(websocket_client, config).(websocket_client, config):
	self.game = "Brotato"
	game_state = ApBrotatoGameState.new(self)
	character_progress = ApCharacterProgress.new(self, game_state)
	shop_slots_progress = ApShopSlotsProgress.new(self, game_state)
	shop_lock_buttons_progress = ApShopLockButtonsProgress.new(self, game_state)
	enemy_xp_progress = ApEnemyXpProgress.new(self, game_state)
	gold_progress = ApGoldProgress.new(self, game_state)
	xp_progress = ApXpProgress.new(self, game_state)
	items_progress = ApItemsProgress.new(self, game_state)
	upgrades_progress = ApUpgradesProgress.new(self, game_state)
	common_loot_crate_progress = ApLootCrateProgress.new(self, game_state, "common")
	legendary_loot_crate_progress = ApLootCrateProgress.new(self, game_state, "legendary")
	waves_progress = ApWavesProgress.new(self, game_state)
	wins_progress = ApWinsProgress.new(self, game_state)
	saved_runs_progress = ApSavedRunsProgress.new(self, game_state)
	deathlink_progress = ApDeathLinkProgress.new(self, game_state)
	debug = GodotApClientDebugSettings.new()

	_progress_trackers = [
		character_progress,
		shop_slots_progress,
		shop_lock_buttons_progress,
		enemy_xp_progress,
		gold_progress,
		xp_progress,
		items_progress,
		upgrades_progress,
		common_loot_crate_progress,
		legendary_loot_crate_progress,
		waves_progress,
		wins_progress,
		saved_runs_progress,
		deathlink_progress
	]

	ModLoaderLog.debug("Brotato AP adapter initialized", _LOG_NAME)


func export_run_specific_progress_data() -> Dictionary:
	## Gather all run-specific data from the progress trackers into a single dictionary.
	##
	## This is meant to complement Brotato's built-in save data, so we can properly load
	## the save and restore any progress data that's specific to that run.
	var data = {}
	for progress in _progress_trackers:
		var run_data = progress.export_run_specific_progress_data()
		data.merge(run_data)
	return data

func load_run_specific_progress_data(data: Dictionary):
	for progress in _progress_trackers:
		progress.load_run_specific_progress_data(data)

func connected_to_multiworld() -> bool:
	# Convenience method to check if connected to AP, so other scenes don't need to 
	# reference the player session just to check this.
	return self.connect_state == self.ConnectState.CONNECTED_TO_MULTIWORLD
