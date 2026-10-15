extends "res://entities/units/player/player.gd"

const LOG_NAME = "RampagingHippy-Archipelago/entities/units/player/player"

onready var _ap_client
var _deathlink_item = preload("res://mods-unpacked/RampagingHippy-Archipelago/content/items/ap_deathlink/ap_deathlink_data.tres")

# Called when the node enters the scene tree for the first time.
func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client
	var _status = _ap_client.deathlink_progress.connect("deathlink_triggered", self, "_on_deathlink_triggered")

func _on_deathlink_triggered(source: String, cause: String):
	var kill_item = _deathlink_item.duplicate()
	kill_item.name = tr("RHAP_WAVE_CLEARED_LABEL_DEATHLINK_DEATH_CAUSE").format({source=source})
	var die_args = Entity.DieArgs.new()
	die_args.from = kill_item
	die(die_args)
