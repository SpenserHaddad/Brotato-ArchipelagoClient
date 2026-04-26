extends MarginContainer

onready var _progress_container = $VBoxContainer/HBoxContainer/UIBetterTabContainer/TabContainer/ProgressContainer

signal back_button_pressed

func init():
	pass

func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	var ap_client = mod_node.brotato_ap_client
	_progress_container.set_client(ap_client)


func _on_BackButton_pressed():
	emit_signal("back_button_pressed")

func _input(event: InputEvent) -> void :
	if event.is_action_released("ui_cancel"):
		emit_signal("back_button_pressed")
