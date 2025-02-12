class_name ArchipelagoModBase
extends Node

# Brotato Archipelago Multiworld Randomizer Client
const MOD_NAME = "RampagingHippy-Archipelago"
const MOD_VERSION = "0.7.2"
const LOG_NAME = MOD_NAME + "/mod_main"

const ApWebSocketConnection = preload("res://mods-unpacked/RampagingHippy-Archipelago/ap/ap_websocket_connection.gd")
var BrotatoApClient = load("res://mods-unpacked/RampagingHippy-Archipelago/ap/brotato_ap_client.gd")

export onready var ap_websocket_connection
export onready var brotato_ap_client

func _init():
	ModLoaderLog.info("Init", LOG_NAME)

	var dir = ModLoaderMod.get_unpacked_dir() + MOD_NAME + "/"
	var ext_dir = dir + "extensions/"

	# Add extensions
	var extension_files = [
		"main.gd", # Update consumable drop logic to spawn AP items
		"singletons/run_data.gd", # Override XP rewards
		"singletons/item_service.gd", # Drop AP consumables
		"ui/menus/pages/main_menu.gd", # Add AP connect
		# Detect when game is quit when the "Return to main menu" confirmation button is pressed
		"ui/menus/pages/menu_confirm.gd",
		# Detect when game is restart when the "Restart" confirmation button is pressed
		"ui/menus/pages/menu_restart.gd",
		"ui/menus/title_screen/title_screen_menus.gd", # Swtich to connect menu when connect button is pressed
		# Unlock only characters received in MultiWorld, show MultiWorld progress
		"ui/menus/run/character_selection.gd",
		# Show character win status in inventory elements
		"ui/menus/shop/inventory.gd",
		# Enable/Disable shop item lock buttons
		"ui/menus/shop/shop_items_container.gd",
		"ui/menus/shop/shop_item.gd",
		# Show character win status on character select screen
		"global/inventory_element.gd",
	]
	
	for ef in extension_files:
		ModLoaderMod.install_script_extension(ext_dir + ef)

	# Add translations
	ModLoaderMod.add_translation(dir + "translations/modname.en.translation")

func _ready() -> void:
	# TODO: Proper translations
	# ModLoaderLog.info(str("Translation Demo: ", tr("MODNAME_READY_TEXT")), LOG_NAME)
	# ModLoaderLog.success("Loaded", LOG_NAME)

	# TODO: Config migrations, add version number and check for matching values.
	var config = ModLoaderConfig.get_config(MOD_NAME, "ap_config")
	if config == null:
		var default_config = ModLoaderConfig.get_default_config(MOD_NAME)
		ModLoaderConfig.create_config(MOD_NAME, "ap_config", default_config.data)
		config = ModLoaderConfig.get_config(MOD_NAME, "ap_config")

	ap_websocket_connection = ApWebSocketConnection.new()
	self.add_child(ap_websocket_connection)

	brotato_ap_client = BrotatoApClient.new(ap_websocket_connection, config)
	self.add_child(brotato_ap_client)

	ModLoaderLog.success("Archipelago mod v%s initialized" % MOD_VERSION, LOG_NAME)

	# We deliberately DON'T add the AP consumables to the full list because we want to 
	# manually control how/when they drop, instead of just adding to the drop pool.

	# var ContentLoader = get_node("/root/ModLoader/Darkly77-ContentLoader/ContentLoader")
	# var content_dir = "res://mods-unpacked/RampagingHippy-Archipelago/content_data/"
	# ContentLoader.load_data(content_dir + "ap_consumables.tres", LOG_NAME)
