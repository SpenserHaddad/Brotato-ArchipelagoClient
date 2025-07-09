## Monitor the game to determine when we're actively in a run or wave.
##
## This lets other parts of the mod, such as the progress trackers, know when to update
## the game or AP client.
extends Object
class_name ApBrotatoGameState

const LOG_NAME = "RampagingHippy-Archipelago/game_state"

var GodotApClient = load("res://mods-unpacked/RampagingHippy-Archipelago/ap/godot_ap_client.gd")

## Signal that a new run has started with the given character.
signal run_started(character_ids)

## Signal that the current run has finished with the given character
##
## The first argument indicates if the run was won or not.
signal run_finished(won_run, character_ids)

## Signal that a new wave in the run as started.
signal wave_started(wave_number, character_ids)

## Signal that the current wave has finished.
signal wave_finished(wave_number, character_ids, is_run_lost, is_run_won)

var _ap_client
var in_run: bool = false
var active_characters: Array = []

func _init(ap_client):
	_ap_client = ap_client

func is_in_ap_run() -> bool:
	## Returns true iff we're actively in a run and connected to an AP server.
	return in_run and _ap_client.connect_state == GodotApClient.ConnectState.CONNECTED_TO_MULTIWORLD

func notify_run_started(character_ids: Array):
	## Called by the game extensions when a new run is started.
	##
	## Emits the `run_started` signal to notify progress trackers.
	in_run = true
	active_characters = character_ids
	var character_names = ", ".join(active_characters)
	if is_in_ap_run():
		ModLoaderLog.info("AP run started with characters; %s" % character_names, LOG_NAME)
		emit_signal("run_started", active_characters)
	else:
		ModLoaderLog.info("Non-AP run started with characters; %s" % character_names, LOG_NAME)

func notify_run_finished(won_run: bool):
	## Called by the game extensions when a run is finished, whether won or lost.
	##
	## Emits the `run_finished` signal to notify progress trackers.
	# Check if this was an AP run before flipping the in_run flag
	var finished_ap_run = is_in_ap_run()
	in_run = false
	active_characters = []
	if finished_ap_run:
		ModLoaderLog.info("AP run finished, won_run=%s" % won_run, LOG_NAME)
		emit_signal("run_finished", won_run, active_characters)
	else:
		ModLoaderLog.info("Non-AP run finished, won_run=%s" % won_run, LOG_NAME)

func notify_wave_started(wave_number: int):
	## Called by the game extensions when a wave is started.
	##
	## Emits the `wave_started` signal to notify progress trackers.
	if is_in_ap_run():
		ModLoaderLog.info("AP wave %d started" % wave_number, LOG_NAME)
		emit_signal("wave_started", wave_number, active_characters)
	else:
		ModLoaderLog.info("Non-AP wave %d started" % wave_number, LOG_NAME)

func notify_wave_finished(wave_number: int, is_run_lost: bool, is_run_won: bool):
	## Called by the game extensions when a wave is finished.
	##
	## Emits the `wave_finished` signal to notify progress trackers.
	if is_in_ap_run():
		ModLoaderLog.info("AP wave %d finished, is_run_lost=%s, is_run_won=%s" % [wave_number, is_run_lost, is_run_won], LOG_NAME)
		emit_signal("wave_finished", wave_number, active_characters, is_run_lost, is_run_won)
	else:
		ModLoaderLog.info("Non-AP wave %d finished, is_run_lost=%s, is_run_won=%s" % [wave_number, is_run_lost, is_run_won], LOG_NAME)
