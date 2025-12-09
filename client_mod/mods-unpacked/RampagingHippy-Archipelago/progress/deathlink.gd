extends "res://mods-unpacked/RampagingHippy-Archipelago/progress/_base.gd"
class_name ApDeathLinkProgress

const LOG_NAME = "RampagingHippy-Archipelago/progress/deathlink"

signal deathlink_triggered(source, cause)

var deathlink_enabled: bool = false

# The source and cause fields from the last DeathLink that caused a run to be
# lost. If multiple DeathLinks happen to come in close together, this will be
# the info from the first one received.
var deathlink_source: String = ""
var deathlink_cause: String = ""

# Set to True while either sending a DeathLink packet (so we don't try to handle
# our own DeathLink), or while killing the player during a received packet from
# another player, and otherwise False
var handling_deathlink: bool = false

# Whether the last run was lost due to DeathLink. This persists until a new run
# is started so post-game handlers like the run summary can query it.
var lost_to_deathlink: bool = false

func _init(ap_client, game_state).(ap_client, game_state):
	var _status = _ap_client.connect("bounced_received", self, "_on_bounced_received")
	return

func on_run_started(_character_ids: Array, _is_new_run: bool):
	# Clear the flags just to be safe
	handling_deathlink = false
	lost_to_deathlink = false
	deathlink_source = ""
	deathlink_cause = ""

func on_wave_finished(wave_number: int, _character_ids: Array, is_run_lost: bool, _is_run_won: bool):
	if is_run_lost and deathlink_enabled and not handling_deathlink:
		ModLoaderLog.info("Sending DeathLink", LOG_NAME)
		var message_template
		if wave_number == 20:
			message_template = "%s choked on wave %d"
		elif wave_number <= 5:
			message_template = "%s had a little skill issue on wave %d"
		else:
			message_template = "%s lost on wave %d"

		var message = message_template % [_ap_client.player, wave_number]
		# The DeathLink Bounce handler should take care of clearing this for us.
		handling_deathlink = true
		_ap_client.send_deathlink("", message)

func on_connected_to_multiworld():
	deathlink_enabled = _ap_client.slot_data.get("deathlink", 0) == 1
	ModLoaderLog.info("Deathlink enabled: %s" % deathlink_enabled, LOG_NAME)
	if deathlink_enabled:
		_ap_client.enable_deathlink()

func _on_bounced_received(bounced_data: Dictionary):
	if deathlink_enabled and bounced_data.get("tags", {}).has("DeathLink"):
		var packet_source = bounced_data.data["source"]
		var packet_cause = bounced_data.data.get("cause", "")
		
		# Check handling_deathlink so we are still killed by others playing in
		# the same slot (AP-level co-op)
		if packet_source == _ap_client.player and handling_deathlink:
			ModLoaderLog.info("Received our own DeathLink, ignoring", LOG_NAME)
			handling_deathlink = false
		# Make sure we don't try to handle multiple DeathLinks at once, since it
		# causes problems
		elif not handling_deathlink and not lost_to_deathlink:
			ModLoaderLog.info("DeathLink received from %s, cause: %s" % [deathlink_source, deathlink_cause], LOG_NAME)
			handling_deathlink = true
			lost_to_deathlink = true
			deathlink_source = packet_source
			deathlink_cause = packet_cause
			emit_signal("deathlink_triggered", deathlink_source, deathlink_cause)
			handling_deathlink = false
			ModLoaderLog.info("Done handling DeathLink", LOG_NAME)
