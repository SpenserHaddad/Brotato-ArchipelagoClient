extends "res://ui/menus/shop/base_shop.gd"

const LOG_NAME = "RampagingHippy-Archipelago/ui/menus/shop/base_shop"
const ApGoToWaveMenu = preload("res://mods-unpacked/RampagingHippy-Archipelago/ui/menus/shop/ap_go_to_wave_menu.tscn")
const BrotatoApConstants = preload("res://mods-unpacked/RampagingHippy-Archipelago/ap/constants.gd")


# Tell Godot about our extensions of types that the base game uses for type checking.
# As far as I can tell, Godot considers our extended versions of these classes to be
# different, incompatible types from their base classes, which results in various
# methods which reference these types in their signatures generating Parser Errors when
# the game switches to a shop. Perhaps the type here is defined before the extensions
# and that breaks something?
# The fix seems to require us to:
#	* Explicitly redefine the types here so Godot picks them up and uses them instead.
#	* Extend coop_shop and shop, which are currently empty.
# This is definitely a hack, but to be fair the root cause is arguably a bug in either
# Godot or ModLoader.
const ShopItem = preload("res://mods-unpacked/RampagingHippy-Archipelago/extensions/ui/menus/shop/shop_item.gd")
const ShopItemsContainer = preload("res://mods-unpacked/RampagingHippy-Archipelago/extensions/ui/menus/shop/shop_items_container.gd")

onready var _ap_client
onready var _constants
onready var _ap_go_to_wave_menu
onready var _original_current_wave: int
onready var _original_go_button_text: String
onready var _original_go_button_tooltip: String

func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client
	if _ap_client.connected_to_multiworld():
		_constants = BrotatoApConstants.new()
		var go_button = _get_go_button(0)
		_original_go_button_text = go_button.text
		_original_go_button_tooltip = go_button.hint_tooltip

		_add_ap_go_to_wave_button()
		_ap_go_to_wave_menu.connect("skip_to_wave_toggled", self, "_on_skip_to_wave_toggled")
		_check_wave_caps()

		_ap_client.waves_progress.connect("wave_cap_increase_received", self, "_on_wave_cap_increase_received")

	_original_current_wave = RunData.current_wave

func _add_ap_go_to_wave_button():
	var go_button = _get_go_button(0)
	var parent_node = go_button.get_parent()

	ModLoaderMod.append_node_in_scene(
		self, "ApGoToWave", parent_node.get_path(), ApGoToWaveMenu.resource_path
	)
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

func _on_wave_cap_increase_received(_character: String):
	# Just check the wave cap for all characters again, it's fast enough that we don't
	# need to check if the increase was for any currently active player.
	_check_wave_caps()

func _check_wave_caps():
	for player_index in RunData.get_player_count():
		var go_button = _get_go_button(player_index)
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
	._on_GoButton_pressed(player_index)
