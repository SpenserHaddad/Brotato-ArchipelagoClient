extends Object
class_name ApBrotatoGameInfo

const ApPlayerSession = preload ("./godot_ap_client.gd")

signal run_started(character_id)
signal run_finished(won_run, character_id)
signal wave_started(wave_number, character_id)
signal wave_finished()

var _ap_client
var in_run: bool = false

func _init(ap_session):
	_ap_client = ap_session
	var _status = _ap_client.connect("connection_state_changed", self, "_on_session_connection_state_changed")

func connected_to_multiworld():
	return _ap_client.connect_state == ApPlayerSession.ConnectState.CONNECTED_TO_MULTIWORLD

func is_in_ap_run():
	return in_run and connected_to_multiworld()

func notify_run_started(character_id: String):
	in_run = true
	emit_signal("run_started", character_id)

func notify_run_finished(won_run: bool, character_id: String):
	in_run = false
	emit_signal("run_finished", won_run, character_id)

func notify_wave_started(wave_number: int, character_id: String):
	emit_signal("wave_started", wave_number, character_id)

func notify_wave_finished(wave_number: int, character_id: String):
	emit_signal("wave_finished", wave_number, character_id)
