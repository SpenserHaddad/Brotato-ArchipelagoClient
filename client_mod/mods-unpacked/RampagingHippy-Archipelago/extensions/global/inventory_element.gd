extends "res://items/global/inventory_element.gd"

const LOG_NAME = "RampagingHippy-Archipelago/ap_char_inventory_element"

func set_character_info(included_in_multiserver: bool, won_run: bool):
	## Intended to be called when this represents a character select icon, adds
	## the "won run" icon (aka an AP icon because I'm creative) and sets it
	## visible if the player won a run with that character.
	ModLoaderMod.append_node_in_scene(
		self,
		"ApWonRunIcon",
		null,
		"res://mods-unpacked/RampagingHippy-Archipelago/ap/ap_won_run_icon.tscn",
		won_run
	)
