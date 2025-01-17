extends "res://singletons/run_data.gd"

onready var _ap_client

func _ready() -> void:
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client

func add_xp(value: int, player_index: int, is_ap_xp: bool = false) -> void:
	# Only add XP if the AP client says so, or if it's an AP item. The enemy XP progress
	# class also checks if we're connected to a multiworld.
	if _ap_client.enemy_xp_progress.enable_enemy_xp or is_ap_xp:
		.add_xp(value, player_index)