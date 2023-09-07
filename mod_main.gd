class_name ArchipelagoModBase
extends Node

# Brotato Archipelago Multiworld Randomizer Client

const MOD_NAME = "RampagingHippy-Archipelago"
export onready var ap_client

func _init(_modLoader = ModLoader):
	ModLoaderLog.info("Init", MOD_NAME)

	var dir = ModLoaderMod.get_unpacked_dir() + MOD_NAME + "/"
	var ext_dir = dir + "extensions/"

	# Add extensions
	var extension_files = [
		"main.gd", # Update consumable drop logic to spawn AP items
		"singletons/item_service.gd", # Drop AP consumables
		"ui/menus/pages/main_menu.gd", # Add AP connect button to main menu
		"ui/menus/title_screen/title_screen_menus.gd", # Swtich to connect menu when connect button is pressed
	]
	
	for ef in extension_files:
		ModLoaderMod.install_script_extension(ext_dir + ef)

	# Add translations
	ModLoaderMod.add_translation(dir + "translations/modname.en.translation")
	

func _ready()->void:
	ModLoaderLog.info("Ready", MOD_NAME)
	# TODO: Proper translations
	ModLoaderLog.info(str("Translation Demo: ", tr("MODNAME_READY_TEXT")), MOD_NAME)
	ModLoaderLog.success("Loaded", MOD_NAME)


	# TODO: Can we turn the service into a singleton somehow? Adding a node to the root
	# didn't seem to work.
	ModLoaderLog.debug("Adding WebSocket Client", MOD_NAME)
	ap_client = ApClientService.new("Brotato")
	self.add_child(ap_client)
	ModLoaderLog.debug("Added WebSocket Client", MOD_NAME)

	# We explicitly DON'T add the AP consumables to the full list because we want to 
	# control how they drop more carefully, and it's easier to control this way than
	# modifying the consumable drop logic.

	# var ContentLoader = get_node("/root/ModLoader/Darkly77-ContentLoader/ContentLoader")
	# var content_dir = "res://mods-unpacked/RampagingHippy-Archipelago/content_data/"
	# ContentLoader.load_data(content_dir + "ap_consumables.tres", MOD_NAME)
