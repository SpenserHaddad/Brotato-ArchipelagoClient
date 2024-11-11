extends PanelContainer

const CHECK_COMPLETE_FADEOUT_TIME_SEC = 2.0
const CHECK_COMPLETE_FADEOUT_START_ALPHA = 0.8
const ENABLED_MODULATE_COLOR = Color.white
const DISABLED_MODULATE_COLOR = Color.darkslategray

onready var _ap_icon_texture = $HBoxContainer/MarginContainer/ApIconTexture 
onready var _crate_texture = $HBoxContainer/MarginContainer/CrateTexture
onready var _progress_label: Label = $HBoxContainer/ProgressLabel
onready var _tween: Tween = $Tween
onready var _timer: Timer = $Timer
export(String) var crate_type = "common"

# TODO: Should be able to just query this off the Scene directly....
var stylebox = StyleBoxFlat.new()

var _loot_crate_progress

func _ready():
	stylebox.bg_color = Color("#0000ff00")
	var _result = _timer.connect("timeout", self, "_on_timer_timeout")
	
	add_stylebox_override("panel", stylebox)
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	var ap_client = mod_node.brotato_ap_client
	if crate_type == "legendary":
		_crate_texture.texture = load("res://items/consumables/legendary_item_box/legendary_item_box.png")
		_loot_crate_progress = ap_client.legendary_loot_crate_progress
	else:
		_crate_texture.texture = load("res://items/consumables/item_box/item_box.png")
		_loot_crate_progress = ap_client.common_loot_crate_progress
	
	_loot_crate_progress.connect("check_progress_changed", self, "update_progress")
	if ap_client.connected_to_multiworld():
		update_progress(_loot_crate_progress.check_progress, _loot_crate_progress.crates_per_check)

func update_progress(progress: int, total: int):
	if _timer.is_stopped():
		# Show the check complete number for a little longer
		_progress_label.set_text("%d/%d" % [progress, total])

	if progress == total:
		# Highlight the Scene to show a check was completed and don't update the
		# text for a short time so the player can see it.
		var _tween_success = _tween.interpolate_property(
			stylebox,
			"bg_color:a",
			CHECK_COMPLETE_FADEOUT_START_ALPHA,
			0.0,
			CHECK_COMPLETE_FADEOUT_TIME_SEC,
			Tween.TRANS_LINEAR,
			Tween.EASE_IN
		)
		var _tween_started = _tween.start()
		_timer.start()

	var modulate_color = ENABLED_MODULATE_COLOR
	if _loot_crate_progress.num_locations_checked >= _loot_crate_progress.num_unlocked_locations:
		# We can't get more checks, make the display grey to indicate that to the player
		modulate_color = DISABLED_MODULATE_COLOR

	_ap_icon_texture.modulate = modulate_color	
	_crate_texture.modulate = modulate_color
	_progress_label.modulate = modulate_color


func _on_timer_timeout():
	update_progress(_loot_crate_progress.check_progress, _loot_crate_progress.crates_per_check)
	
