extends "res://entities/units/player/player.gd"

const LOG_NAME = "RampagingHippy-Archipelago/entities/units/player/player"

onready var _ap_client

# Called when the node enters the scene tree for the first time.
func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client
	var _status = _ap_client.deathlink_progress.connect("deathlink_triggered", self, "_on_deathlink_triggered")

func _on_deathlink_triggered(source: String, cause: String):
	die()
