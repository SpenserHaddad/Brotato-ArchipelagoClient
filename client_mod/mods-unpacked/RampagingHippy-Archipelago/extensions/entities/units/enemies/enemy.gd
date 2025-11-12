# extends "res://entities/entity.gd"
extends "res://entities/units/enemies/enemy.gd"

const LOG_NAME = "RampagingHippy-Archipelago/entities/units/enemies/enemy"

onready var _ap_client

func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client

func die(args: = Entity.DieArgs.new()) -> void :
	# Check if we should spawn a crate for debugging
	var old_unit_always_drop_consumable = self.stats.get("always_drop_consumables")
	# An enemy died, handle debug crates 
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
