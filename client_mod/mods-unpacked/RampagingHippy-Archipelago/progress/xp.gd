## Track XP received from Archipelago items, and give them to the player.
##
## XP items are meant to be given to the player once, so they can't snowball too
## quickly. If the player is in a run, they receive the XP immediately, otherwise this
## class tracks the amount of XP received from AP but not given to the player, and
## gives it to them when they start a new run.
##
## This class listens for XP items to be received by the client, and also uses a data
## storage key to keep track of the XP given to the player so we can track the value
## between multiple game sessions. This class handles initializing the key when first 
## connecting and updating it when we give the player XP.
extends ApProgressBase
class_name ApXpProgress

var xp_received: int = 0
var xp_given: int = 0
var _received_xp_data_storage_key: String = ""

func _init(ap_client, game_state).(ap_client, game_state):
	var _status = _ap_client.connect(
		"data_storage_updated",
		self,
		"_on_session_data_storage_updated"
	)

func give_player_unreceived_xp():
	## Give the player any buffered XP if they're in a run.
	if _game_state.is_in_ap_run():
		var xp_to_give = xp_received - xp_given
		if xp_to_give > 0:
			RunData.add_xp(xp_to_give)
			_ap_client.set_value(
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
	# Reset received XP. As the multiworld sends us all our received items we'll
	# recalculate the received XP.
	xp_received = 0
	_received_xp_data_storage_key = "%s_xp_given" % _ap_client.player
	# Initialize the data storage value if it wasn't set yet
	_ap_client.set_value(
		_received_xp_data_storage_key,
		"default",
		0,
		0,
		true
	)

func on_run_started(_character_id: String):
	give_player_unreceived_xp()

func _on_session_data_storage_updated(key: String, new_value, _original_value=null):
	if key == _received_xp_data_storage_key:
		xp_given = new_value
