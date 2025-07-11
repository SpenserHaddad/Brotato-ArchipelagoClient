class_name ArchipelagoModBase
extends Node

# Brotato Archipelago Multiworld Randomizer Client
const MOD_NAME = "RampagingHippy-Archipelago"
const MOD_VERSION = "0.9.0"
const LOG_NAME = MOD_NAME + "/mod_main"

const ApWebSocketConnection = preload("res://mods-unpacked/RampagingHippy-Archipelago/ap/ap_websocket_connection.gd")
var BrotatoApClient = load("res://mods-unpacked/RampagingHippy-Archipelago/ap/brotato_ap_client.gd")

export onready var ap_websocket_connection
export onready var brotato_ap_client

func _init():
	ModLoaderLog.info("Init", LOG_NAME)

	var dir = ModLoaderMod.get_unpacked_dir() + MOD_NAME + "/"
	var ext_dir = dir + "extensions/"

	ModLoaderLog.info("Setting up extensions", LOG_NAME)

	# Add extensions
	var extension_files = [
		"main.gd", # Update consumable drop logic to spawn AP items
		"entities/entity.gd", # Track when units are killed to drop consumables in debug mode
		"singletons/run_data.gd", # Override XP rewards
		"singletons/item_service.gd", # Drop AP consumables
		"singletons/progress_data.gd", # Save AP runs for each character
		"ui/menus/pages/main_menu.gd", # Add AP connect
		# Detect when game is quit when the "Return to main menu" confirmation button is pressed
		"ui/menus/pages/menu_confirm.gd",
		# Detect when game is restart when the "Restart" confirmation button is pressed
		"ui/menus/pages/menu_restart.gd",
		"ui/menus/title_screen/title_screen_menus.gd", # Switch to connect menu when connect button is pressed
		# Unlock only characters received in MultiWorld, show MultiWorld progress
		"ui/menus/run/character_selection.gd",
		# Show character win status in inventory elements
		"ui/menus/shop/inventory.gd",
		# Show "Go To Wave" Button (single player and coop)
		"ui/menus/shop/base_shop.gd",
		# Fix weird issue where the shops won't load (see comments in files for details)
		"ui/menus/shop/shop.gd",
		"ui/menus/shop/coop_shop.gd",
		# Enable/Disable shop item lock buttons
		"ui/menus/shop/shop_items_container.gd",
		"ui/menus/shop/shop_item.gd",
		# Show character win status on character select screen
		"global/inventory_element.gd",
	]
	
	for ef in extension_files:
		ModLoaderMod.install_script_extension(ext_dir + ef)

	ModLoaderLog.info("Setup extensions", LOG_NAME)

	# Add translations
	ModLoaderMod.add_translation(dir + "translations/modname.en.translation")
	ModLoaderLog.info("Added translations", LOG_NAME)

func _ready() -> void:
	# TODO: Proper translations
	# ModLoaderLog.info(str("Translation Demo: ", tr("MODNAME_READY_TEXT")), LOG_NAME)
	# ModLoaderLog.success("Loaded", LOG_NAME)
	# TODO: Config migrations, add version number and check for matching values.
	ModLoaderLog.info("Getting config", LOG_NAME)

	var config = ModLoaderConfig.get_config(MOD_NAME, "ap_config")
	if config == null:
		ModLoaderLog.info("Config null", LOG_NAME)

		var default_config = ModLoaderConfig.get_default_config(MOD_NAME)
		ModLoaderLog.info("Got default config", LOG_NAME)
		
		ModLoaderConfig.create_config(MOD_NAME, "ap_config", default_config.data)
		ModLoaderLog.info("Created default config", LOG_NAME)

		config = ModLoaderConfig.get_config(MOD_NAME, "ap_config")
		ModLoaderLog.info("Got config again", LOG_NAME)


	ModLoaderLog.info("Got config", LOG_NAME)

	ap_websocket_connection = ApWebSocketConnection.new()
	ModLoaderLog.info("Created webscoket, adding...", LOG_NAME)
	self.add_child(ap_websocket_connection)

	ModLoaderLog.info("Creating client", LOG_NAME)

	brotato_ap_client = BrotatoApClient.new(ap_websocket_connection, config)
	ModLoaderLog.info("Adding client...", LOG_NAME)
	self.add_child(brotato_ap_client)

	ModLoaderLog.success("Archipelago mod v%s initialized" % MOD_VERSION, LOG_NAME)

	# We deliberately DON'T add the AP consumables to the full list because we want to 
	# manually control how/when they drop, instead of just adding to the drop pool.

	# var ContentLoader = get_node("/root/ModLoader/Darkly77-ContentLoader/ContentLoader")
	# var content_dir = "res://mods-unpacked/RampagingHippy-Archipelago/content_data/"
	# ContentLoader.load_data(content_dir + "ap_consumables.tres", LOG_NAME)
