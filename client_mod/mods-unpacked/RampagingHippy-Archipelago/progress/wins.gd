extends ApProgressBase
class_name ApWinsProgress

var wins_for_goal: int
var num_wins: int = 0
var characters_won_with: PoolStringArray = []

func _init(ap_session, game_state).(ap_session, game_state):
	var _status = _game_state.connect("run_finished", self, "_on_run_finished")

func _on_run_finished(won_run: bool, character_id: String):
	if won_run:
		var character_name = constants.CHARACTER_ID_TO_NAME[character_id]
		var character_won_loc_name = constants.RUN_COMPLETE_LOCATION_TEMPLATE.format({"char": character_name})
		var character_won_loc_id = _ap_client.data_package.location_name_to_id[character_won_loc_name]
		_ap_client.check_location(character_won_loc_id)

func on_item_received(item_name: String, _item):
	if item_name == "Run Won":
		num_wins += 1
		if num_wins >= wins_for_goal:
			_ap_client.set_status(ApTypes.ClientStatus.CLIENT_GOAL)

func on_connected_to_multiworld():
	wins_for_goal = _ap_client.slot_data["num_wins_needed"]
