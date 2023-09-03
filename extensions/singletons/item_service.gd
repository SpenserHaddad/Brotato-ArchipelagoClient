extends "res://singletons/item_service.gd"

# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.

var _dropped_ap_item_wave = 0
var _ap_items_by_tier = {}

func init_unlocked_pool() -> void:
	.init_unlocked_pool()
	_ap_items_by_tier[Tier.COMMON] = load("res://mods-unpacked/RampagingHippy-Archipelago/content/consumables/ap_pickup_common.tres")
	_ap_items_by_tier[Tier.UNCOMMON] = load("res://mods-unpacked/RampagingHippy-Archipelago/content/consumables/ap_pickup_uncommon.tres")
	_ap_items_by_tier[Tier.RARE] = load("res://mods-unpacked/RampagingHippy-Archipelago/content/consumables/ap_pickup_rare.tres")
	_ap_items_by_tier[Tier.LEGENDARY] = load("res://mods-unpacked/RampagingHippy-Archipelago/content/consumables/ap_pickup_legendary.tres")
	ModLoaderLog.debug("Init unlock pool, printing consumables.", ArchipelagoModBase.MOD_NAME)


func get_consumable_to_drop(tier:int= Tier.COMMON) -> ConsumableData:
	if _dropped_ap_item_wave < RunData.current_wave:
		ModLoaderLog.debug("Dropping AP item of tier %d for wave %d." % [tier, RunData.current_wave], ArchipelagoModBase.MOD_NAME)
		_dropped_ap_item_wave = RunData.current_wave
		return _ap_items_by_tier[tier]
	else:
		return .get_consumable_to_drop(tier)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
