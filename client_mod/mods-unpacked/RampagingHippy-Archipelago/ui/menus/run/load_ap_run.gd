class_name ApLoadSavedRunSelection
extends Control

onready var _weapons_container = $"%WeaponsContainer"
onready var _items_container = $"%ItemsContainer"
onready var _stats_container = $"%StatsContainer"
onready var _gold_container = $"%GoldContainer"
onready var _wave_label = $"%WaveLabel"
onready var _background = $"%Background"
onready var _resume_button = $"%ResumeButton"
onready var _stat_popup = $StatPopup
onready var _item_popup = $ItemPopup
onready var _popup_manager: PopupManager = $PopupManager

onready var _ap_client

var _saved_game_state
var _saved_ap_state

var _saved_game_characters: Array = []

func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client

	var player_character = RunData.get_player_character(0)
	if player_character == null:
		return
	var saved_run_raw = _ap_client.saved_runs_progress.get_saved_run(player_character.my_id)
	
	var loader_v2 = ProgressDataLoaderV2.new("")
	_saved_game_state = loader_v2.deserialize_run_state(saved_run_raw["game_state"])
	_saved_ap_state = saved_run_raw["ap_state"]
	var player_data = _saved_game_state["players_data"][0]
	
	RunData.players_data[0].current_level = player_data.current_level
	for item in player_data.items:
		if not item.my_id.begins_with("character_"):
			RunData.add_item(item, 0)
	
	for weapon in player_data.weapons:
		RunData.add_weapon(weapon, 0)

	TempStats.reset()
	LinkedStats.reset()
	
	_stats_container.disable_focus()
	_stats_container.update_player_stats(0)
	
	_popup_manager.add_item_popup(_item_popup, 0)
	_popup_manager.connect_inventory_container(_weapons_container)
	_popup_manager.connect_inventory_container(_items_container)
	
	_popup_manager.add_stat_popup(_stat_popup, 0)
	_popup_manager.connect_stats_container(_stats_container)

	var weapons = RunData.players_data[0].weapons
	var items = RunData.players_data[0].items
	
	_weapons_container.set_data("WEAPONS", Category.WEAPON, weapons)
	_items_container.set_data("ITEMS", Category.ITEM, items, true, true)
	_gold_container.update_value(player_data.gold)
	_wave_label.text = "Wave %d" % _saved_game_state["current_wave"]
	_background.texture = ZoneService.get_zone_data(_saved_game_state.current_zone).ui_background
	
	_resume_button.grab_focus()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()

func _on_NewRunButton_pressed():
	# Clear our changes for the load preview so we can resume the normal new game flow.
	var player_characters = []
	for player_index in RunData.get_player_count():
		player_characters.push_back(RunData.get_player_character(player_index))

	RunData.revert_all_selections()
	for player_index in RunData.get_player_count():
		RunData.add_character(player_characters[player_index], player_index)

	if RunData.some_player_has_weapon_slots():
		get_tree().change_scene(MenuData.weapon_selection_scene)
	else:
		get_tree().change_scene(MenuData.difficulty_selection_scene)


func _on_ResumeButton_pressed():
	var characters = []
	for player_idx in RunData.get_player_count():
		characters.push_back(RunData.get_player_character(player_idx).my_id)
	_ap_client.game_state.notify_run_started(characters)
	
	ProgressData.saved_run_state = _saved_game_state
	RunData.resume_from_state(_saved_game_state)
	RunData.resumed_from_state_in_shop = true
	_ap_client.load_run_specific_progress_data(_saved_ap_state)
	var scene = "res://ui/menus/shop/shop.tscn"
	var _error = get_tree().change_scene(scene)

func _go_back():
	for player_index in RunData.get_player_count():
		Utils.last_elt_selected[player_index] = RunData.get_player_character(player_index)
	RunData.revert_all_selections()
	get_tree().change_scene(MenuData.character_selection_scene)

func _on_BackButton_pressed():
	_go_back()
