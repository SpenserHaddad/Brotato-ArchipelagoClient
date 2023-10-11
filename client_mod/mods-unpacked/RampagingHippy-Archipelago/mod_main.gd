class_name ArchipelagoModBase
extends Node

# Brotato Archipelago Multiworld Randomizer Client

const MOD_NAME = "RampagingHippy-Archipelago"
const LOG_NAME = MOD_NAME + "/mod_main"
export onready var ap_client
export onready var brotato_client

func _init(_modLoader = ModLoader):
	ModLoaderLog.info("Init", LOG_NAME)

	var dir = ModLoaderMod.get_unpacked_dir() + MOD_NAME + "/"
	var ext_dir = dir + "extensions/"

	# Add extensions
	var extension_files = [
		"main.gd", # Update consumable drop logic to spawn AP items
		"singletons/item_service.gd", # Drop AP consumables
		"ui/menus/pages/main_menu.gd", # Add AP connect button to main menu
		"ui/menus/title_screen/title_screen_menus.gd", # Swtich to connect menu when connect button is pressed
		"ui/menus/run/character_selection.gd", # Only unlock characters received in MultiWorld
	]
	
	for ef in extension_files:
		ModLoaderMod.install_script_extension(ext_dir + ef)

	# Add translations
	ModLoaderMod.add_translation(dir + "translations/modname.en.translation")
	

func _ready()->void:
	# TODO: Proper translations
	ModLoaderLog.info(str("Translation Demo: ", tr("MODNAME_READY_TEXT")), LOG_NAME)
	ModLoaderLog.success("Loaded", LOG_NAME)

	# TODO: Can we turn the service into a singleton somehow? Adding a node to the root
	# didn't seem to work.
	var _ap_client_class = load("res://mods-unpacked/RampagingHippy-Archipelago/singletons/ap_client_service.gd")
	ap_client = _ap_client_class.new()
	self.add_child(ap_client)
	ModLoaderLog.debug("Added WebSocket client", LOG_NAME)

	var _brotato_client_class = load("res://mods-unpacked/RampagingHippy-Archipelago/singletons/brotato_ap_adapter.gd")
	brotato_client = BrotatoApAdapter.new(ap_client)
	self.add_child(brotato_client)
	ModLoaderLog.debug("Added AP client", LOG_NAME)

	# We deliberately DON'T add the AP consumables to the full list because we want to 
	# manually control how/when they drop, instead of just adding to the drop pool.

	# var ContentLoader = get_node("/root/ModLoader/Darkly77-ContentLoader/ContentLoader")
	# var content_dir = "res://mods-unpacked/RampagingHippy-Archipelago/content_data/"
	# ContentLoader.load_data(content_dir + "ap_consumables.tres", LOG_NAME)
