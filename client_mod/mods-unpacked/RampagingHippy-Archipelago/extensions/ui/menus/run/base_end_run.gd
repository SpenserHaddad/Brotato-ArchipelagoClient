extends "res://ui/menus/run/base_end_run.gd"

const LOG_NAME = "RampagingHippy-Archipelago/ui/menus/run/base_end_run"

onready var _ap_client

func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client
	
	if _ap_client.deathlink_progress.lost_to_deathlink:
		var new_title_text = "Lost due to DeathLink from %s" % _ap_client.deathlink_progress.deathlink_source
		if _ap_client.deathlink_progress.deathlink_cause:
			new_title_text += ": %s" % _ap_client.deathlink_progress.deathlink_cause
		_title.text = new_title_text
