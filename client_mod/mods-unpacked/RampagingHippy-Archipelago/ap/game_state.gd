## Monitor the game to determine when we're actively in a run or wave.
##
## This lets other parts of the mod, such as the progress trackers, know when to update
## the game or AP client.
extends Object
class_name ApBrotatoGameState

const BrotatoApClient = preload ("res://mods-unpacked/RampagingHippy-Archipelago/ap/constants.gd")

## Signal that a new run has started with the given character.
signal run_started(character_id)

## Signal that the current run has finished with the given character
##
## The first argument indicates if the run was won or not.
signal run_finished(won_run, character_id)

## Signal that a new wave in the run as started.
signal wave_started(wave_number, character_id)

## Signal that the current wave has finished.
signal wave_finished()

var _ap_client
var in_run: bool = false

func _init(ap_client):
	_ap_client = ap_client

func is_in_ap_run() -> bool:
	## Returns true iff we're actively in a run and connected to an AP server.
	return in_run and _ap_client.connect_state == GodotApClient.ConnectState.CONNECTED_TO_MULTIWORLD

func notify_run_started(character_id: String):
	## Called by the game extensions when a new run is started.
	##
	## Emits the `run_started` signal to notify progress trackers.
	in_run = true
	if is_in_ap_run():
		emit_signal("run_started", character_id)

func notify_run_finished(won_run: bool, character_id: String):
	## Called by the game extensions when a run is finished, whether won or lost.
	##
	## Emits the `run_finished` signal to notify progress trackers.
	# Check if this was an AP run before flipping the in_run flag
	var finished_ap_run = is_in_ap_run()
	in_run = false
	if finished_ap_run:
		emit_signal("run_finished", won_run, character_id)

func notify_wave_started(wave_number: int, character_id: String):
	## Called by the game extensions when a wave is started.
	##
	## Emits the `wave_started` signal to notify progress trackers.
	if is_in_ap_run():
		emit_signal("wave_started", wave_number, character_id)

func notify_wave_finished(wave_number: int, character_id: String):
	## Called by the game extensions when a wave is finished.
	##
	## Emits the `wave_finished` signal to notify progress trackers.
	if is_in_ap_run():
		emit_signal("wave_finished", wave_number, character_id)
