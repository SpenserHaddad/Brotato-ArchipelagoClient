extends "res://main.gd"

var _ap_gift_common = preload("res://mods-unpacked/RampagingHippy-Archipelago/content/consumables/ap_gift_items/ap_gift_item_common.tres")
var _ap_gift_uncommon = preload("res://mods-unpacked/RampagingHippy-Archipelago/content/consumables/ap_gift_items/ap_gift_item_uncommon.tres")
var _ap_gift_rare = preload("res://mods-unpacked/RampagingHippy-Archipelago/content/consumables/ap_gift_items/ap_gift_item_rare.tres")
var _ap_gift_legendary = preload("res://mods-unpacked/RampagingHippy-Archipelago/content/consumables/ap_gift_items/ap_gift_item_legendary.tres")

export (Resource) var ap_upgrade_to_process_icon = preload("res://mods-unpacked/RampagingHippy-Archipelago/ap_upgrade_icon.png")

# Extensions
var _drop_ap_pickup = true;
onready var _brotato_client: BrotatoApAdapter

func _ready() -> void:
	var mod_node: ArchipelagoModBase = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_brotato_client = mod_node.brotato_client
	
	if RunData.current_wave == 1:
		# Run started, initialize/reset some values
		_brotato_client.run_started()
		var ap_game_data = _brotato_client.game_data
		ModLoaderLog.debug("Start of run, giving player %d XP and %d gold." % [ap_game_data.starting_xp, ap_game_data.starting_gold], ArchipelagoModBase.MOD_NAME)
		
		RunData.add_xp(ap_game_data.starting_xp)
		RunData.add_gold(ap_game_data.starting_gold)
		
		for gift_tier in _brotato_client.game_data.received_items_by_tier:
			var num_gifts = _brotato_client.game_data.received_items_by_tier[gift_tier]
			ModLoaderLog.debug("Giving player %d items of tier %d." % [num_gifts, gift_tier], ArchipelagoModBase.MOD_NAME)
			for _i in range(num_gifts):
				_on_ap_item_received(gift_tier)

		for upgrade_tier in _brotato_client.game_data.received_upgrades_by_tier:
			var num_upgrades = _brotato_client.game_data.received_upgrades_by_tier[upgrade_tier]
			ModLoaderLog.debug("Giving player %d upgrades of tier %d." % [num_upgrades, upgrade_tier], ArchipelagoModBase.MOD_NAME)
			for _i in range(num_upgrades):
				_on_ap_upgrade_received(upgrade_tier)

	var _status = _brotato_client.connect("xp_received", self, "_on_ap_xp_received")
	_status = _brotato_client.connect("gold_received", self, "_on_ap_gold_received")
	_status = _brotato_client.connect("item_received", self, "_on_ap_item_received")
	_status = _brotato_client.connect("upgrade_received", self, "_on_ap_upgrade_received")

func _on_ap_xp_received(xp_amount: int):
	ModLoaderLog.info("%d XP received" % xp_amount, ArchipelagoModBase.MOD_NAME)
	RunData.add_xp(xp_amount)

func _on_ap_gold_received(gold_amount: int):
	ModLoaderLog.info("%d Gold received" % gold_amount, ArchipelagoModBase.MOD_NAME)
	RunData.add_gold(gold_amount)

func _on_ap_item_received(item_tier: int):
	var item_data
	match item_tier:
		Tier.COMMON:
			item_data = _ap_gift_common
		Tier.UNCOMMON:
			item_data = _ap_gift_uncommon
		Tier.RARE:
			item_data = _ap_gift_rare
		Tier.LEGENDARY:
			item_data = _ap_gift_legendary
	_consumables_to_process.push_back(item_data)

func _on_ap_upgrade_received(upgrade_tier: int):
	var upgrade_level: int
	# Brotato gives items of set tiers at multiples of 5. Use this to give the correct
	# tier item without modifying the original code too much.
	match upgrade_tier:
		Tier.COMMON:
			# We override get_upgrade_data to set the tier to COMMON if the level is -1.
			upgrade_level = -1
		Tier.UNCOMMON:
			upgrade_level = 5
		Tier.RARE:
			upgrade_level = 10
		Tier.LEGENDARY:
			upgrade_level = 25
	# Taken from on_levelled_up
	emit_signal("upgrade_to_process_added", ap_upgrade_to_process_icon, upgrade_level)
	_upgrades_to_process.push_back(upgrade_level)

func _on_WaveTimer_timeout() -> void:
	_brotato_client.wave_won(RunData.current_character.my_id, RunData.current_wave)
	._on_WaveTimer_timeout()

func apply_run_won():
	_brotato_client.run_won(RunData.current_character.my_id)
	.apply_run_won()
