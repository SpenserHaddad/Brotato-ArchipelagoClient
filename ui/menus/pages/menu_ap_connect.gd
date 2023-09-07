extends MarginContainer

signal connect_button_pressed

onready var _connect_button: Button = $"%VBoxContainer/ConnectButton"
onready var _host_edit: LineEdit = $"VBoxContainer/CenterContainer/GridContainer/HostEdit"
onready var _player_edit: LineEdit = $"VBoxContainer/CenterContainer/GridContainer/PlayerEdit"
onready var _password_edit: LineEdit = $"VBoxContainer/CenterContainer/GridContainer/PasswordEdit"

func init():
	# Needed to make the scene swich in title_screen_menus happy.
	pass

func _ready():
	pass

#func _input(_event):
#	if get_tree().current_scene.name == self.name && Input.is_key_pressed(KEY_ENTER):
#		_on_ConnectButton_pressed()

func _on_ConnectButton_pressed():
	var mod_node: ArchipelagoModBase = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	var ap_client: ApClientService = mod_node.ap_client
	var server_info = _host_edit.text.rsplit(":", false, 1)
	var server = server_info[0]
	var port = int(server_info[1])
	var player = _player_edit.text
	var password = _password_edit.text
	ap_client.connect_to_multiworld(server, port, player, password)
	emit_signal("connect_button_pressed")
