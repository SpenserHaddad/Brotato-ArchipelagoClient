class_name ApLoadSavedRunSelection
extends Control

onready var _weapons_container = $"%WeaponsContainer"
onready var _items_container = $"%ItemsContainer"
onready var _stats_container = $"%StatsContainer"
onready var _background = $"%Background"
onready var _stat_popup = $StatPopup
onready var _item_popup = $ItemPopup
onready var _popup_manager: PopupManager = $PopupManager

onready var _ap_client

var _saved_run

func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client
	
	TempStats.reset()
	LinkedStats.reset()
	
	_stats_container.disable_focus()
	_stats_container.update_player_stats(0)
	
	_popup_manager.add_item_popup(_item_popup, 0)
	_popup_manager.connect_inventory_container(_weapons_container)
	_popup_manager.connect_inventory_container(_items_container)
	
	_popup_manager.add_stat_popup(_stat_popup, 0)
	_popup_manager.connect_stats_container(_stats_container)

	var weapons = RunData.get_player_weapons(0)
	var items = RunData.get_player_items(0)
	_weapons_container.set_data("WEAPONS", Category.WEAPON, weapons)
	_items_container.set_data("ITEMS", Category.ITEM, items, true, true)

	_background.texture = ZoneService.get_zone_data(RunData.current_zone).ui_background
