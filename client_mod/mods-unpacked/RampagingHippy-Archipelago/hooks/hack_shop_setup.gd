# Adds the "skip to wave" UI to the shop when connected to a multiworld.
# Ideally, we'd do this in a base_shop.gd extension, but there's some Godot weirdness
# preventing this (see the base_shop.gd extension for details), so we do it outside the
# class, applying the hook whenever we enter the shop.

class_name ApShopSetupHook
extends Node

const LOG_NAME = "RampagingHippy-Archipelago/hooks/hack_shop_setup"
const ApGoToWaveMenu = preload("res://mods-unpacked/RampagingHippy-Archipelago/ui/menus/shop/ap_go_to_wave_menu.tscn")
const BrotatoApConstants = preload("res://mods-unpacked/RampagingHippy-Archipelago/ap/constants.gd")

onready var _ap_client
onready var _game_state
onready var _constants
onready var _ap_go_to_wave_menu
onready var _original_current_wave: int
onready var _original_go_button_text: String
onready var _original_go_button_tooltip: String

var shop_node: BaseShop

func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client
	_constants = BrotatoApConstants.new()
	_game_state = _ap_client.game_state
	var _success = get_tree().connect("node_added", self, "_on_node_added")

func _on_node_added(node: Node):
	if _ap_client.connected_to_multiworld() and node is BaseShop:
		ModLoaderLog.info("BaseShop added!", LOG_NAME)
		shop_node = node
		node.connect("ready", self, "_modify_base_shop")

func _modify_base_shop():
	ModLoaderLog.info("Adding AP controls to BaseShop!", LOG_NAME)

	var go_button = shop_node._get_go_button(0)
	_original_go_button_text = go_button.text
	_original_go_button_tooltip = go_button.hint_tooltip
	_add_ap_go_to_wave_button(go_button)
	_ap_go_to_wave_menu.connect("skip_to_wave_updated", self, "_on_skip_to_wave_updated")
	_check_wave_caps()

	_ap_client.waves_progress.connect("wave_cap_increase_received", self, "_on_wave_cap_increase_received")

	_original_current_wave = RunData.current_wave

func _add_ap_go_to_wave_button(go_button: Button):
	var parent_node = go_button.get_parent()

	ModLoaderMod.append_node_in_scene(
		self, "ApGoToWave", parent_node.get_path(), ApGoToWaveMenu.resource_path
	)
	_ap_go_to_wave_menu = parent_node.get_node("ApGoToWave")
	_ap_go_to_wave_menu.focus_neighbour_top = go_button.get_path()
	go_button.set_focus_neighbour(MARGIN_BOTTOM, NodePath("../ApGoToWave/SkipToWaveButton"))


func _on_skip_to_wave_updated(enabled: bool, skip_to_wave: int):
	var new_next_wave: int
	if enabled:
		new_next_wave = skip_to_wave
	else:
		# Copied from vanilla RunData get_next_wave
		new_next_wave = RunData.current_wave + 1 - RunData.get_wave_reset_count()

	var go_button = shop_node._get_go_button(0)
	go_button.text = tr(shop_node.go_text) + " (" + Text.text("WAVE", [str(new_next_wave)]) + ")"

func _on_wave_cap_increase_received(_character: String):
	# Just check the wave cap for all characters again, it's fast enough that we don't
	# need to check if the increase was for any currently active player.
	_check_wave_caps()

func _check_wave_caps():
	if shop_node == null:
		# Don't do anything if we're not in a shop. This can happen when we
		# receive a wave cap increase anywhere but in a shop.
		return
	for player_index in RunData.get_player_count():
		var go_button = shop_node._get_go_button(player_index)
		var player_character_id = RunData.players_data[player_index].current_character.my_id
		var player_character_name = _constants.CHARACTER_ID_TO_NAME[player_character_id]
		var can_play_wave = _ap_client.waves_progress.can_play_wave(RunData.current_wave+1, player_character_name)
		if can_play_wave:
			go_button.disabled = false
			go_button.text = _original_go_button_text
			go_button.hint_tooltip = _original_go_button_tooltip
		else:
			go_button.disabled = true
			go_button.text = "RHAP_MENU_SHOP_WAVE_CAP_REACHED"
			var item_name = _constants.PROGRESSIVE_WAVE_CAP_INCREASE_ITEM_TEMPLATE.format({char=player_character_name})
			go_button.hint_tooltip = tr("RHAP_MENU_SHOP_WAVE_CAP_REACHED_TOOLTIP").format({item_name=item_name})


func _on_GoButton_pressed(player_index: int):
	if player_index == 0:
		if _ap_client.connected_to_multiworld() and _ap_go_to_wave_menu.skip_to_wave > 0:
			ModLoaderLog.debug("Skipping to wave %d" % _ap_go_to_wave_menu.skip_to_wave, LOG_NAME)
			# The normal "Go to next wave" routine increments the current wave by 1.
			# We don't have any better control over the next wave than setting the
			# value to one less than our desired wave and letting the game handle the
			# rest. It's a bit of a hack.
			RunData.current_wave = _ap_go_to_wave_menu.skip_to_wave - 1
		elif player_index == 0:
			RunData.current_wave = _original_current_wave

	# Trigger the normal go to next wave flow. Only player 1 has a skip to wave button.
	shop_node._on_GoButton_pressed(player_index)
