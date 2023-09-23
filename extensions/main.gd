extends "res://main.gd"

# Extensions
var _drop_ap_pickup = true;
onready var _brotato_client: BrotatoApAdapter

func _ready() -> void:
	var mod_node: ArchipelagoModBase = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_brotato_client = mod_node.brotato_client
	
	if RunData.current_wave == 1:
		var ap_game_data = _brotato_client.game_data
		ModLoaderLog.debug("Start of run, giving player %d XP and %d gold." % [ap_game_data.starting_xp, ap_game_data.starting_gold], ArchipelagoModBase.MOD_NAME)
		
		RunData.add_xp(ap_game_data.starting_xp)
		RunData.add_gold(ap_game_data.starting_gold)
	var _status = _brotato_client.connect("xp_received", self, "_on_ap_xp_received")
	_status = _brotato_client.connect("gold_received", self, "_on_ap_gold_received")

func _on_ap_xp_received(xp_amount: int):
	ModLoaderLog.info("%d XP received" % xp_amount, ArchipelagoModBase.MOD_NAME)
	RunData.add_xp(xp_amount)

func _on_ap_gold_received(gold_amount: int):
	ModLoaderLog.info("%d Gold received" % gold_amount, ArchipelagoModBase.MOD_NAME)
	RunData.add_gold(gold_amount)

func _on_WaveTimer_timeout() -> void:
	_brotato_client.wave_won(RunData.current_character.my_id, RunData.current_wave)
	._on_WaveTimer_timeout()

func apply_run_won():
	_brotato_client.run_won(RunData.current_character.my_id)
	.apply_run_won()
