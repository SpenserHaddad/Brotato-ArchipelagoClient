extends "res://ui/menus/pages/menu_confirm.gd"

const LOG_NAME = "RampagingHippy-Archipelago/menu_confirm"

var _ap_client

func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client

func _on_ConfirmButton_pressed() -> void:
	ModLoaderLog.debug("Quitting current run", LOG_NAME)
	_ap_client.game_state.notify_run_finished(false)
	._on_ConfirmButton_pressed()
