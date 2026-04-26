extends PanelContainer
class_name ApSlotDataContainer


const BrotatoApClient = preload("res://mods-unpacked/RampagingHippy-Archipelago/ap/brotato_ap_client.gd")

onready var _ap_client
onready var _settings_container: VBoxContainer = $MarginContainer/SettingsContainer
onready var _wins_setting = $MarginContainer/SettingsContainer/WinsSetting
onready var _deathlink_setting = $MarginContainer/SettingsContainer/DeathlinkSetting
onready var _waves_with_checks_setting = $MarginContainer/SettingsContainer/WavesWithChecksSetting
onready var _gold_reward_mode_setting = $MarginContainer/SettingsContainer/GoldRewardModeSetting
onready var _xp_reward_mode_setting = $MarginContainer/SettingsContainer/XpRewardModeSetting
onready var _enemy_xp_setting = $MarginContainer/SettingsContainer/EnemyXpSetting
onready var _starting_shop_slots_setting = $MarginContainer/SettingsContainer/StartingShopSlotsSetting
onready var _starting_shop_lock_buttons_setting = $MarginContainer/SettingsContainer/StartingShopLockButtonsSetting
onready var _spawn_loot_crates_setting = $MarginContainer/SettingsContainer/SpawnLootCratesSetting
onready var _num_common_loot_crates_setting = $MarginContainer/SettingsContainer/NumCommonLootCratesSetting
onready var _num_common_loot_crate_drops_per_check_setting = $MarginContainer/SettingsContainer/NumCommonLootCrateDropsPerCheckSetting
onready var _num_common_loot_crate_groups_setting = $MarginContainer/SettingsContainer/NumCommonLootCrateGroups
onready var _num_legendary_loot_crates_setting = $MarginContainer/SettingsContainer/NumLegendaryLootCratesSetting
onready var _num_legendary_loot_crate_drops_per_check_setting = $MarginContainer/SettingsContainer/NumLegendaryLootCrateDropsPerCheckSetting
onready var _num_legendary_loot_crate_groups_setting = $MarginContainer/SettingsContainer/NumLegendaryLootCrateGroups
onready var _abyssal_terrors_dlc_setting = $MarginContainer/SettingsContainer/AbyssalTerrorsDlcEnabledSetting

func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_client = mod_node.brotato_ap_client
	_ap_client.connect("connection_state_changed", self, "_on_connection_state_changed")

	_on_connection_state_changed(_ap_client.connect_state)
	
func _on_connection_state_changed(new_state: int, error: int = 0):
	match new_state:
		BrotatoApClient.ConnectState.CONNECTED_TO_MULTIWORLD:
			_update_settings()
		BrotatoApClient.ConnectState.DISCONNECTED:
			for child in _settings_container.get_children():
				child.set_value("N/A")

func _update_settings():
	var slot_data = _ap_client.slot_data
	_wins_setting.set_value(str(slot_data["num_wins_needed"]))
	
	_deathlink_setting.set_value(_enabled_setting_to_str(slot_data["deathlink"]))
	
	var waves_with_checks: Array = slot_data["waves_with_checks"]
	if len(waves_with_checks) < 20:
		var waves_with_checks_str= PoolStringArray(waves_with_checks)
		var waves_with_checks_value = waves_with_checks_str.join(", ")
		_waves_with_checks_setting.set_value(waves_with_checks_value)
	else:
		# Simplify the string if there's a check for every wave so it fits on-screen.
		_waves_with_checks_setting.set_value("1-20")
	
	var gold_reward_mode_value: String
	if slot_data["gold_reward_mode"] == 0:
		gold_reward_mode_value = "One Time"
	else:
		gold_reward_mode_value = "All Every Time"
	
	_gold_reward_mode_setting.set_value(_reward_mode_setting_to_str(slot_data["gold_reward_mode"]))
	_xp_reward_mode_setting.set_value(_reward_mode_setting_to_str(slot_data["xp_reward_mode"]))
	_enemy_xp_setting.set_value(_enabled_setting_to_str(slot_data["enable_enemy_xp"]))
	_starting_shop_slots_setting.set_value(str(slot_data["num_starting_shop_slots"]))
	_starting_shop_lock_buttons_setting.set_value(str(slot_data["num_starting_shop_lock_buttons"]))
	_spawn_loot_crates_setting.set_value(_enabled_setting_to_str(slot_data["spawn_normal_loot_crates"]))
	_num_common_loot_crates_setting.set_value(str(slot_data["num_common_crate_locations"]))
	_num_common_loot_crate_drops_per_check_setting.set_value(str(slot_data["num_common_crate_drops_per_check"]))
	_num_common_loot_crate_groups_setting.set_value(str(len(slot_data["common_crate_drop_groups"])))
	_num_legendary_loot_crates_setting.set_value(str(slot_data["num_legendary_crate_locations"]))
	_num_legendary_loot_crate_drops_per_check_setting.set_value(str(slot_data["num_legendary_crate_drops_per_check"]))
	_num_legendary_loot_crate_groups_setting.set_value(str(len(slot_data["legendary_crate_drop_groups"])))
	_abyssal_terrors_dlc_setting.set_value(_enabled_setting_to_str(slot_data["enable_abyssal_terrors_dlc"]))

func _enabled_setting_to_str(value) -> String:
	if value:
		return "Enabled"
	else:
		return "Disabled"
		
func _reward_mode_setting_to_str(value) -> String:
	if value == 0:
		return "One Time"
	else:
		return "All Every Time"
	
