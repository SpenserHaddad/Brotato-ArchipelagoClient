extends "res://singletons/run_data.gd"

onready var _ap_client

func _ready() -> void:
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client
	var _status = _ap_client.xp_progress.connect("xp_received", self, "_on_ap_xp_received")
	_status = _ap_client.gold_progress.connect("gold_received", self, "_on_ap_gold_received")

func _on_ap_xp_received(amount: int):
	for player_index in RunData.get_player_count():
		add_xp(amount, player_index, true)

func _on_ap_gold_received(amount: int):
	for player_index in RunData.get_player_count():
		add_gold(amount, player_index)

func add_xp(value: int, player_index: int, is_ap_xp: bool = false) -> void:
	# Only add XP if the AP client says so, or if it's an AP item. The enemy XP progress
	# class also checks if we're connected to a multiworld.
	if _ap_client.enemy_xp_progress.enable_enemy_xp or is_ap_xp:
		.add_xp(value, player_index)