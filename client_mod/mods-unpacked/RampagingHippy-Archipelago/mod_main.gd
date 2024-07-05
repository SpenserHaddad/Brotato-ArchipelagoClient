class_name ArchipelagoModBase
extends Node

# Brotato Archipelago Multiworld Randomizer Client
const MOD_NAME = "RampagingHippy-Archipelago"
const LOG_NAME = MOD_NAME + "/mod_main"

const ApWebSocketConnection = preload ("res://mods-unpacked/RampagingHippy-Archipelago/singletons/ap_websocket_connection.gd")
const BrotatoApClient = preload ("res://mods-unpacked/RampagingHippy-Archipelago/singletons/brotato_ap_client.gd")

export onready var ap_websocket_connection
export onready var brotato_ap_client

func _init():
	ModLoaderLog.info("Init", LOG_NAME)

	var dir = ModLoaderMod.get_unpacked_dir() + MOD_NAME + "/"
	var ext_dir = dir + "extensions/"

	# Add extensions
	var extension_files = [
		"main.gd", # Update consumable drop logic to spawn AP items
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
		# Show character win status on character select screen
		"global/inventory_element.gd",
	]
	
	for ef in extension_files:
		ModLoaderMod.install_script_extension(ext_dir + ef)

	# Add translations
	ModLoaderMod.add_translation(dir + "translations/modname.en.translation")

func _ready() -> void:
	# TODO: Proper translations
	ModLoaderLog.info(str("Translation Demo: ", tr("MODNAME_READY_TEXT")), LOG_NAME)
	ModLoaderLog.success("Loaded", LOG_NAME)

	# TODO: Can we turn the service into a singleton somehow? Adding a node to the root
	# didn't seem to work.
	ap_websocket_connection = ApWebSocketConnection.new()
	self.add_child(ap_websocket_connection)

	brotato_ap_client = BrotatoApClient.new(ap_websocket_connection)
	self.add_child(brotato_ap_client)

	ModLoaderLog.debug("Archipelago mod initialized", LOG_NAME)

	# We deliberately DON'T add the AP consumables to the full list because we want to 
	# manually control how/when they drop, instead of just adding to the drop pool.

	# var ContentLoader = get_node("/root/ModLoader/Darkly77-ContentLoader/ContentLoader")
	# var content_dir = "res://mods-unpacked/RampagingHippy-Archipelago/content_data/"
	# ContentLoader.load_data(content_dir + "ap_consumables.tres", LOG_NAME)
