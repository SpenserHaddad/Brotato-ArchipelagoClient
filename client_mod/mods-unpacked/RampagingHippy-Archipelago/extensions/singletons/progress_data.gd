extends "res://singletons/progress_data.gd"

const LOG_NAME = "RampagingHippy-Archipelago/progress_data"

onready var _ap_client

func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client

func save_run_state(
	shop_items = [],
	reroll_count = [],
	paid_reroll_count = [],
	initial_free_rerolls = [],
	free_rerolls = [],
	item_steals = []
) -> void:
	ModLoaderLog.debug("Saving run state", LOG_NAME)

	if _ap_client.connected_to_multiworld() and RunData.get_player_count() == 1:
		var run_state = get_run_state(
			shop_items, 
			reroll_count, 
			paid_reroll_count, 
			initial_free_rerolls, 
			free_rerolls, 
			item_steals
		)
		var loader_v2 = ProgressDataLoaderV2.new(SAVE_DIR) # Dummy value
		_set_loader_properties(loader_v2, saved_run_state)
		var saved_run_serialized = loader_v2.serialize_run_state(saved_run_state)
		var ap_run_state = _ap_client.export_run_specific_progress_data()
		var character = RunData.get_player_character(0).my_id
		_ap_client.saved_runs_progress.save_character_run(
			character, saved_run_serialized, ap_run_state
		)
	else:
		.save_run_state(
			shop_items,
			reroll_count,
			paid_reroll_count,
			initial_free_rerolls,
			free_rerolls,
			item_steals
		)
		

func save() -> void:
	# Disable saving when connected to Multiworld
	if not _ap_client.connected_to_multiworld():
		.save()
