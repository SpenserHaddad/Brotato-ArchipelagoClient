extends ApProgressBase
class_name ApGoldProgress

var gold_received: int = 0
var gold_given: int = 0
var _received_gold_data_storage_key: String = ""

func _init(ap_session, game_state).(ap_session, game_state):
	var _status = _ap_session.connect(
		"data_storage_updated",
		self,
		"_on_session_data_storage_updated"
	)

func give_player_unreceived_gold():
	var in_run = _game_state.is_in_ap_run()
	if _game_state.is_in_ap_run():
		var gold_to_give = gold_received - gold_given
		if gold_to_give > 0:
			RunData.add_gold(gold_to_give)
			_ap_session.set_value(
				_received_gold_data_storage_key,
				"add",
				gold_to_give,
				0,
				true
			)

func on_item_received(item_name: String, _item):
	if item_name in constants.GOLD_DROP_NAME_TO_VALUE:
		gold_received += constants.GOLD_DROP_NAME_TO_VALUE[item_name]
		give_player_unreceived_gold()

func on_connected_to_multiworld():
	# Reset received gold. The items will tell how much we have for this multiworld.
	gold_received = 0
	_received_gold_data_storage_key = "%s_gold_given" % _ap_session.player
	# Initialize the data storage value if it wasn't set yet
	_ap_session.set_value(
		_received_gold_data_storage_key,
		"default",
		0,
		0,
		true
	)

func on_run_started(_character_id: String):
	give_player_unreceived_gold()

func _on_session_data_storage_updated(key: String, new_value, _original_value=null):
	if key == _received_gold_data_storage_key:
		gold_given = new_value
