extends "res://entities/units/player/player.gd"

const LOG_NAME = "RampagingHippy-Archipelago/entities/units/player/player"

onready var _ap_client

# Called when the node enters the scene tree for the first time.
func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client
	var _status = _ap_client.deathlink_progress.connect("deathlink_triggered", self, "_on_deathlink_triggered")

func _on_deathlink_triggered(source: String, cause: String):
	var die_args = Entity.DieArgs.new()
	die_args.killing_blow_dmg_value = 999
	die(die_args)

func die(args := Entity.DieArgs.new()) -> void:
	ModLoaderLog.info("Player is dying, dead=%s" % dead, LOG_NAME)
	.die(args)
