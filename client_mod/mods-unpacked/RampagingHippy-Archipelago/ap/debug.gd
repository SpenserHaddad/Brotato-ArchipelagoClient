extends Object
class_name GodotApClientDebugSettings

const LOG_NAME = "RampagingHippy-Archipelago/ap/debug"

# When enabled, drop loot crate every n kills. Referenced in main and item_service.
var enable_auto_spawn_loot_crate: bool = false
var auto_spawn_loot_crate: bool = false
var auto_spawn_loot_crate_counter: int = 0
var auto_spawn_loot_crate_on_count: int = 5

func _init():
	ModLoaderLog.debug("debug_spawn_loot_crate=%s" % enable_auto_spawn_loot_crate, LOG_NAME)

func notify_enemy_killed():
	if enable_auto_spawn_loot_crate:
		auto_spawn_loot_crate_counter += 1
		if auto_spawn_loot_crate_counter > auto_spawn_loot_crate_on_count:
			auto_spawn_loot_crate = true

func notify_debug_crate_spawned():
	auto_spawn_loot_crate = false
	auto_spawn_loot_crate_counter = 0
