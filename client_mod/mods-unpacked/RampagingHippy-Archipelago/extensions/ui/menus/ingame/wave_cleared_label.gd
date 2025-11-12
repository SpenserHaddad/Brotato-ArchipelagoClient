extends "res://ui/menus/ingame/wave_cleared_label.gd"

const LOG_NAME = "RampagingHippy-Archipelago/ui/menus/ingame/wave_cleared_label"


onready var _ap_client

func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client


func start(is_wave_failed := false, is_run_lost := false, is_run_won := false) -> void:
	.start(is_wave_failed, is_run_lost, is_run_won)
	
	if is_run_lost and _ap_client.deathlink_progress.handling_deathlink:
		text = "DeathLink Received"
