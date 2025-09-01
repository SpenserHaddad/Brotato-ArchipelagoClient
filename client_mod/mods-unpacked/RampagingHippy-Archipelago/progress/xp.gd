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
extends "res://mods-unpacked/RampagingHippy-Archipelago/progress/_base.gd"
class_name ApXpProgress

const LOG_NAME = "RampagingHippy-Archipelago/progress/xp"
const SAVE_DATA_KEY = "progress_xp"

signal xp_received

# The total XP received from items, given or not given.
var xp_received: int = 0

# The XP given to the player, which is either per run or per game depending on
# the player's settings.
var xp_given: int = 0
var xp_reward_mode: int = 0
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
			emit_signal("xp_received", xp_to_give)

			if xp_reward_mode == constants.XpRewardMode.ONE_TIME:
				# Send the gold received to the server so we don't give the
				# player this gold again
				_ap_client.set_value(
					_received_xp_data_storage_key,
					"add",
					xp_to_give,
					0,
					true
				)
			else:
				# Store the tracked gold locally
				xp_given += xp_to_give

func on_item_received(item_name: String, _item):
	if item_name in constants.XP_ITEM_NAME_TO_VALUE:
		xp_received += constants.XP_ITEM_NAME_TO_VALUE[item_name]
		give_player_unreceived_xp()

func on_connected_to_multiworld():
	# Reset received XP. As the multiworld sends us all our received items we'll
	# recalculate the received XP.
	xp_received = 0

	if _ap_client.slot_data.has("xp_reward_mode"):
		xp_reward_mode = _ap_client.slot_data["xp_reward_mode"]
		ModLoaderLog.debug("XP reward mode is %d" % xp_reward_mode, LOG_NAME)
	else:
		xp_reward_mode = constants.XpRewardMode.ONE_TIME
		ModLoaderLog.debug("Legacy mode, XP reward mode is one_time.", LOG_NAME)

	# Initialize the data storage value if it wasn't set yet. Do this regardless of
	# whether we'll use it for simplicity.
	_received_xp_data_storage_key = "%s_xp_given" % _ap_client.player
	_ap_client.set_value(
		_received_xp_data_storage_key,
		"default",
		0,
		0,
		true
	)

func on_run_started(_character_ids: Array, is_new_run: bool):
	if xp_reward_mode == constants.XpRewardMode.ALL_EVERY_TIME and is_new_run:
		# Reset the received XP so we give the player all gold items again.
		# Only do once when starting a run so we don't give a player gold twice.
		xp_given = 0
	# Always give unreceived XP, even on retry, in case some came in while they were
	# on the menu (maybe they went AFK?)
	give_player_unreceived_xp()

func export_run_specific_progress_data() -> Dictionary:
	return {SAVE_DATA_KEY: {"xp_given": xp_given}}

func load_run_specific_progress_data(data: Dictionary):
	xp_given = data[SAVE_DATA_KEY]["xp_given"]
	give_player_unreceived_xp()

func _on_session_data_storage_updated(key: String, new_value, _original_value = null):
	if key == _received_xp_data_storage_key:
		xp_given = new_value
