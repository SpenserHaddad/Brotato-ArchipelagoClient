extends "res://ui/menus/shop/shop.gd"

const LOG_NAME = "RampagingHippy-Archipelago/ui/menus/shop/shop"
const ApGoToWaveMenu = preload("res://mods-unpacked/RampagingHippy-Archipelago/ui/menus/shop/ap_go_to_wave_menu.tscn")

onready var _ap_client
onready var _ap_go_to_wave_menu
onready var _original_current_wave: int


func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client
	if _ap_client.connected_to_multiworld():
		_add_ap_go_to_wave_button()
		_ap_go_to_wave_menu.connect("skip_to_wave_toggled", self, "_on_skip_to_wave_toggled")
		_original_current_wave = RunData.current_wave

func _add_ap_go_to_wave_button():
	var parent_node: Container = $Content/MarginContainer/HBoxContainer/VBoxContainer2

	ModLoaderMod.append_node_in_scene(
		self, "ApGoToWave", parent_node.get_path(), ApGoToWaveMenu.resource_path
	)
	var go_button = _get_go_button(0)
	_ap_go_to_wave_menu = parent_node.get_node("ApGoToWave")
	_ap_go_to_wave_menu.focus_neighbour_top = go_button.get_path()
	go_button.set_focus_neighbour(MARGIN_BOTTOM, NodePath("../ApGoToWave/SkipToWaveButton"))

func _on_skip_to_wave_toggled(enabled: bool):
	var new_next_wave: int
	if enabled:
		new_next_wave = _ap_go_to_wave_menu.skip_to_wave
	else:
		new_next_wave = RunData.current_wave + 1
			
	var go_button = _get_go_button(0)
	go_button.text = tr(go_text) + " (" + Text.text("WAVE", [str(new_next_wave)]) + ")"

func _on_GoButton_pressed(player_index: int):
	if _ap_go_to_wave_menu.skip_to_wave > 0:
		ModLoaderLog.debug("Skipping to wave %d" % _ap_go_to_wave_menu.skip_to_wave, LOG_NAME)
		# The normal "Go to next wave" routine increments the current wave by 1.
		# We don't have any better control over the next wave than setting the
		# value to one less than our desired wave and letting the game handle the
		# rest. It's a bit of a hack.
		RunData.current_wave = _ap_go_to_wave_menu.skip_to_wave - 1
	else:
		RunData.current_wave = _original_current_wave

	# Trigger the normal go to next wave flow. Only player 1 has a skip to wave button.
	._on_GoButton_pressed(player_index)
