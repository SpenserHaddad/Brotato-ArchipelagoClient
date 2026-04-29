extends PanelContainer


onready var _ap_client
onready var _deathlink_mode_button = $MarginContainer/VBoxContainer/HBoxContainer/DeathlinkModeButton

func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client
	_deathlink_mode_button.select(_ap_client.deathlink_progress.get_deathlink_mode())

func _on_DeathlinkModeButton_item_selected(index):
	var item_id = _deathlink_mode_button.get_item_id(index)
	# The IDs match DeathlinkEnableMode currently. If that changes this will
	# need to be done properly
	_ap_client.deathlink_progress.set_deathlink_mode(item_id)


func _on_OpenLogFileDirButton_pressed():
	var log_path_resolved = ProjectSettings.globalize_path(ModLoaderLog.MOD_LOG_PATH).get_base_dir()
	var _error = OS.shell_open(log_path_resolved)


func _on_OpenArchipelagoDiscordButton_pressed():
	# Link to the Brotato channel on the AP Discord specifically.
	OS.shell_open("https://discord.com/channels/731205301247803413/1154944430097313803")
