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

const LOG_NAME = "RampagingHippy-Archipelago/progress/gold"
const SAVE_DATA_KEY = "progress_gold"

signal gold_received

# The total gold received from items, given or not given.
var gold_received: int = 0

# The gold given to the player, which is either per run or per game depending on
# the player's settings.
var gold_given: int = 0
var gold_reward_mode: int = 0
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
			emit_signal("gold_received", gold_to_give)

			if gold_reward_mode == constants.GoldRewardMode.ONE_TIME:
				# Send the gold received to the server so we don't give the
				# player this gold again
				_ap_client.set_value(
					_received_gold_data_storage_key,
					"add",
					gold_to_give,
					0,
					true
				)
			else:
				gold_given += gold_to_give

func on_item_received(item_name: String, _item):
	if item_name in constants.GOLD_DROP_NAME_TO_VALUE:
		gold_received += constants.GOLD_DROP_NAME_TO_VALUE[item_name]
		give_player_unreceived_gold()

func on_connected_to_multiworld():
	# Reset received gold. As the multiworld sends us all our received items we'll
	# recalculate the received gold.
	gold_received = 0
	
	# Check gold reward mode
	if _ap_client.slot_data.has("gold_reward_mode"):
		gold_reward_mode = _ap_client.slot_data["gold_reward_mode"]
		ModLoaderLog.debug("Gold reward mode is %d" % gold_reward_mode, LOG_NAME)
	else:
		gold_reward_mode = constants.GoldRewardMode.ONE_TIME
		ModLoaderLog.debug("Legacy mode, gold reward mode is one_time.", LOG_NAME)
		
	# Initialize the data storage value if it wasn't set yet. Do this regardless of
	# whether we'll use it for simplicity.
	_received_gold_data_storage_key = "%s_gold_given" % _ap_client.player
	_ap_client.set_value(
		_received_gold_data_storage_key,
		"default",
		0,
		0,
		# Ask for the value to come back in case the key is already initialized.
		true
	)

func on_run_started(_character_ids: Array, is_new_run: bool):
	if gold_reward_mode == constants.GoldRewardMode.ALL_EVERY_TIME and is_new_run:
		# Reset the received gold so we give the player all gold items again.
		# Do only when a run is started so we don't give them gold twice.
		gold_given = 0
	# Always give unreceived gold, even on retry, in case some came in while they were
	# on the menu (maybe they went AFK?)
	give_player_unreceived_gold()

func export_run_specific_progress_data() -> Dictionary:
	return {SAVE_DATA_KEY: {"gold_given": gold_given}}

func load_run_specific_progress_data(data: Dictionary):
	gold_given = data[SAVE_DATA_KEY]["gold_given"]
	give_player_unreceived_gold()

func _on_session_data_storage_updated(key: String, new_value, _original_value = null):
	if key == _received_gold_data_storage_key:
		gold_given = new_value
