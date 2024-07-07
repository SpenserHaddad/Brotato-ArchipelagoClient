extends Object
class_name GodotApClientDebugSettings

const LOG_NAME = "RampagingHippy-Archipelago/ap/debug"

# When enabled, drop loot crate every n kills. Referenced in main and item_service.
var auto_spawn_loot_crate: bool = false
var auto_spawn_loot_crate_counter = 0
var auto_spawn_loot_crate_on_count = 3

func _init():
	ModLoaderLog.debug("debug_spawn_loot_crate=%s" % auto_spawn_loot_crate, LOG_NAME)
