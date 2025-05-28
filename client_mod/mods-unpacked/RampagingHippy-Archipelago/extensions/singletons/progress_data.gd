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
	.save_run_state(shop_items, reroll_count, paid_reroll_count, initial_free_rerolls, free_rerolls, item_steals)
	var ap_save_dir = SAVE_DIR + "/ap_saves"
	var directory = Directory.new()

	if not directory.dir_exists(ap_save_dir):
		var created_dir = directory.make_dir(ap_save_dir)
		if created_dir != OK:
			ModLoaderLog.error("Failed to create AP save dir, error is %s." % created_dir, LOG_NAME)
			return

	var loader_v2 = ProgressDataLoaderV2.new(ap_save_dir)
	_set_loader_properties(loader_v2, saved_run_state)
	var saved_run_serialized = loader_v2.serialize_run_state(saved_run_state)
	var saved_run_json = JSON.print(saved_run_serialized)

	var current_run_char = saved_run_state["players_data"][0].current_character.my_id.trim_prefix("character_")
	var ap_save_file_path = "%s/%s.json" % [ap_save_dir, current_run_char]
	ModLoaderLog.info("Saving AP run to %s" % ap_save_file_path, LOG_NAME)

	var ap_save_file = File.new()
	ap_save_file.open(ap_save_file_path, File.WRITE)
	ap_save_file.store_string(saved_run_json)
	ap_save_file.close()
