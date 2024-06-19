extends ApProgressBase
class_name ApXpProgress

var xp_received: int = 0
var xp_given: int = 0
var _received_xp_data_storage_key: String = ""

func _init(ap_session, game_state).(ap_session, game_state):
	var _status = _ap_session.connect(
		"data_storage_updated",
		self,
		"_on_session_data_storage_updated"
	)

func give_player_unreceived_xp():
	if _game_state.is_in_ap_run():
		var xp_to_give = xp_received - xp_given
		if xp_to_give > 0:
			RunData.add_xp(xp_to_give)
			_ap_session.set_value(
				_received_xp_data_storage_key,
				"add",
				xp_to_give,
				0,
				true
			)

func on_item_received(item_name: String, _item):
	if item_name in constants.XP_ITEM_NAME_TO_VALUE:
		xp_received += constants.XP_ITEM_NAME_TO_VALUE[item_name]
		give_player_unreceived_xp()

func on_connected_to_multiworld():
	_received_xp_data_storage_key = "%s_xp_given" % _ap_session.player
	# Initialize the data storage value if it wasn't set yet
	_ap_session.set_value(
		_received_xp_data_storage_key,
		"default",
		0,
		0,
		false
	)

func on_run_started(_character_id: String):
	give_player_unreceived_xp()

func _on_session_data_storage_updated(key: String, new_value, _original_value=null):
	if key == _received_xp_data_storage_key:
		xp_given = new_value
