extends "res://ui/menus/run/base_end_run.gd"

const LOG_NAME = "RampagingHippy-Archipelago/ui/menus/run/base_end_run"

onready var _ap_client

func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client
	
	if _ap_client.deathlink_progress.lost_to_deathlink:
		var deathlink_source = _ap_client.deathlink_progress.deathlink_source
		var deathlink_cause = _ap_client.deathlink_progress.deathlink_cause
		if deathlink_cause:
			_title.text = tr("RHAP_END_RUN_LOST_TO_DEATHLINK_WITH_CAUSE").format({source=deathlink_source, cause=deathlink_cause})
		else:
			_title.text = tr("RHAP_END_RUN_LOST_TO_DEATHLINK_NO_CAUSE").format({source=deathlink_source})
