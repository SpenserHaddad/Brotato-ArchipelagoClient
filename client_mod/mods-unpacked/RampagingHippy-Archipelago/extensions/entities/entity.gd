extends "res://entities/entity.gd"

const LOG_NAME = "RampagingHippy-Archipelago/entities/entity"

onready var _ap_client

func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client

func die(args := DieArgs.new()) -> void:
	var old_unit_always_drop_consumable = self.stats.always_drop_consumables
	_ap_client.debug.notify_enemy_killed()
	if _ap_client.debug.auto_spawn_loot_crate:
		ModLoaderLog.debug("Debug spawning consumable", LOG_NAME)
		# Tell the unit to drop a consumable
		self.stats.always_drop_consumables = true
		# Tell our item_service extension to force the consumable to be a
		# loot crate
		_ap_client.debug.auto_spawn_loot_crate = true
		_ap_client.debug.auto_spawn_loot_crate_counter = 0

	.die(args)
	self.stats.always_drop_consumables = old_unit_always_drop_consumable
