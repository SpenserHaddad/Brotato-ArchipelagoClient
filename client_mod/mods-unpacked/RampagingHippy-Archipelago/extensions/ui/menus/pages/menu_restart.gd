extends "res://ui/menus/pages/menu_restart.gd"

const LOG_NAME = "RampagingHippy-Archipelago/menu_restart"

var _ap_client

func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client

func _on_ConfirmButton_pressed() -> void:
	# The base class does this, so probably better that we do too
	if confirm_button_pressed:
		return
	ModLoaderLog.debug("Restarting current run", LOG_NAME)
	_ap_client.game_state.run_finished()
	._on_ConfirmButton_pressed()
