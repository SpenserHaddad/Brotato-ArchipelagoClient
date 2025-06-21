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

	if _ap_client.connected_to_multiworld() and RunData.get_player_count() == 1:
		# var slot_save_dir = _get_save_dir_for_slot()
		var loader_v2 = ProgressDataLoaderV2.new(SAVE_DIR)
		_set_loader_properties(loader_v2, saved_run_state)
		var saved_run_serialized = loader_v2.serialize_run_state(saved_run_state)
		# var saved_run_json = JSON.print(saved_run_serialized)
		var character = RunData.get_player_character(0).my_id
		_ap_client.saved_runs_progress.save_character_run(character, saved_run_serialized)
		
		# var current_run_chars = []
		# for i in range(RunData.get_player_count()):
		# 	current_run_chars.append(RunData.get_player_character(i).my_id.trim_prefix("character_"))
		# var run_file_name = "_".join(current_run_chars)
		# var ap_save_file_path = "%s/%s.json" % [slot_save_dir, run_file_name]
		# ModLoaderLog.info("Saving AP run to %s" % ap_save_file_path, LOG_NAME)

		# var ap_save_file = File.new()
		# ap_save_file.open(ap_save_file_path, File.WRITE)
		# ap_save_file.store_string(saved_run_json)
		# ap_save_file.close()

func _get_save_dir_for_slot() -> String:
	var server_safe = _ap_client.server.replace(":", "_").replace(".", "_").replace("/", "_")
	var save_dir = "%s_%s" % [server_safe, _ap_client.player]

	var ap_save_dir = SAVE_DIR + "/ap_saves"
	var directory = Directory.new()

	if not directory.dir_exists(ap_save_dir):
		var created_dir = directory.make_dir(ap_save_dir)
		if created_dir != OK:
			ModLoaderLog.error("Failed to create AP save dir, error is %s." % created_dir, LOG_NAME)
			return ""

	var slot_save_dir = ap_save_dir + "/" + save_dir
	if not directory.dir_exists(slot_save_dir):
		var created_dir = directory.make_dir(ap_save_dir)
		if created_dir != OK:
			ModLoaderLog.error("Failed to create AP save dir, error is %s." % created_dir, LOG_NAME)
			return ""

	return slot_save_dir
