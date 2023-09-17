extends "res://main.gd"

# Extensions
var _drop_ap_pickup = true;
onready var _brotato_client: BrotatoApAdapter

func _ready() -> void:
	ModLoaderLog.info("AP main ready, wave %d" % RunData.current_wave, ArchipelagoModBase.MOD_NAME)
	var mod_node: ArchipelagoModBase = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_brotato_client = mod_node.brotato_client
	
	if RunData.current_wave == 1:
		var ap_game_data = _brotato_client.game_data
		ModLoaderLog.debug("Start of run, giving player %d XP and %d gold." % [ap_game_data.starting_xp, ap_game_data.starting_gold], ArchipelagoModBase.MOD_NAME)
		
		RunData.add_xp(ap_game_data.starting_xp)
		RunData.add_gold(ap_game_data.starting_gold)
	var _status = _brotato_client.connect("xp_received", self, "_on_ap_xp_received")
	_status = _brotato_client.connect("gold_received", self, "_on_ap_gold_received")

func _on_ap_xp_received(xp_amount: int):
	ModLoaderLog.info("%d XP received" % xp_amount, ArchipelagoModBase.MOD_NAME)
	RunData.add_xp(xp_amount)

func _on_ap_gold_received(gold_amount: int):
	ModLoaderLog.info("%d Gold received" % gold_amount, ArchipelagoModBase.MOD_NAME)
	RunData.add_gold(gold_amount)

#func spawn_consumables(unit: Unit) -> void:
#	if _drop_ap_pickup:
#		ModLoaderLog.debug("DROP AP ITEM", ArchipelagoModBase.MOD_NAME)
#		_drop_ap_pickup = false
#	.spawn_consumables(unit)
#
#func clean_up_room(is_last_wave: bool = false, is_run_lost: bool = false, is_run_won: bool =false) -> void:
#	ModLoaderLog.debug("Resetting drop_item_check", ArchipelagoModBase.MOD_NAME)
#	_drop_ap_pickup = false
#	.clean_up_room(is_last_wave, is_run_lost, is_run_won)

#func on_consumable_picked_up(consumable: Node):
#	if consumable.consumable_data.my_id.begins_with("ap_item"):
#		ModLoaderLog.info("Picked up AP consumable", ArchipelagoModBase.MOD_NAME)
#		_brotato_client.item_picked_up(consumable)
#	.on_consumable_picked_up(consumable)
#
