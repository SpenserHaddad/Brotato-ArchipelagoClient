extends HBoxContainer

#export(Resource) onready var loot_crate_image = preload("res://items/consumables/item_box/item_box.png")
onready var _crate_texture = $MarginContainer/CrateTexture
onready var _progress_label: Label = $ProgressLabel
export(String) var crate_type = "common"

var _loot_crate_progress

func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	var ap_client = mod_node.brotato_ap_client
	if crate_type == "legendary":
		_crate_texture.texture = load("res://items/consumables/legendary_item_box/legendary_item_box.png")
		_loot_crate_progress = ap_client.legendary_loot_crate_progress
	else:
		_crate_texture.texture = load("res://items/consumables/item_box/item_box.png")
		_loot_crate_progress = ap_client.common_loot_crate_progress
	
	_loot_crate_progress.connect("crate_picked_up", self, "update_progress")
	if ap_client.connected_to_multiworld():
		update_progress()

func update_progress():
	_progress_label.set_text("%d/%d" % [_loot_crate_progress.check_progress, _loot_crate_progress.crates_per_check])
