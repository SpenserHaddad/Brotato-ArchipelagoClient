## Track gold received from Archipelago items, and give it to the player.
##
## Gold items are meant to be given to the player once, so they can't snowball too
## quickly. If the player is in a run, they receive the gold immediately, otherwise this
## class tracks the amount of gold received from AP but not given to the player, and
## gives it to them when they start a new run.
##
## This class listens for gold items to be received by the client, and also uses a data
## storage key to keep track of the gold given to the player so we can track the value
## between multiple game sessions. This class handles initializing the key when first 
## connecting and updating it when we give the player gold.
extends "res://mods-unpacked/RampagingHippy-Archipelago/progress/_base.gd"
class_name ApGoldProgress

var gold_received: int = 0
var gold_given: int = 0
var _received_gold_data_storage_key: String = ""

func _init(ap_client, game_state).(ap_client, game_state):
	var _status = _ap_client.connect(
		"data_storage_updated",
		self,
		"_on_session_data_storage_updated"
	)

func give_player_unreceived_gold():
	## Give the player any buffered gold if they're in a run.
	if _game_state.is_in_ap_run():
		var gold_to_give = gold_received - gold_given
		if gold_to_give > 0:
			RunData.add_gold(gold_to_give)
			_ap_client.set_value(
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
	# Reset received gold. As the multiworld sends us all our received items we'll
	# recalculate the received gold.
	gold_received = 0
	_received_gold_data_storage_key = "%s_gold_given" % _ap_client.player
	# Initialize the data storage value if it wasn't set yet
	_ap_client.set_value(
		_received_gold_data_storage_key,
		"default",
		0,
		0,
		# Ask for the value to come back in case the key is already initialized.
		true
	)

func on_run_started(_character_id: String):
	give_player_unreceived_gold()

func _on_session_data_storage_updated(key: String, new_value, _original_value=null):
	if key == _received_gold_data_storage_key:
		gold_given = new_value
