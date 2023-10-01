extends MarginContainer

signal back_button_pressed

onready var _connect_button: Button = $"VBoxContainer/ConnectButton"
onready var _disconnect_button: Button = $"VBoxContainer/DisconnectButton"
onready var _connect_status_label: Label = $"VBoxContainer/ConnectStatusLabel"
onready var _host_edit: LineEdit = $"VBoxContainer/CenterContainer/GridContainer/HostEdit"
onready var _player_edit: LineEdit = $"VBoxContainer/CenterContainer/GridContainer/PlayerEdit"
onready var _password_edit: LineEdit = $"VBoxContainer/CenterContainer/GridContainer/PasswordEdit"

onready var ap_client: ApClientService
onready var brotato_client: BrotatoApAdapter


func init():
	# Needed to make the scene switch in title_screen_menus happy.
	pass

func _ready():
	var mod_node: ArchipelagoModBase = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	ap_client = mod_node.ap_client
	ap_client.connect("connection_state_changed", self, "_on_connection_state_changed")
	brotato_client = mod_node.brotato_client
	_on_connection_state_changed(ap_client.connection_state)

#func _input(_event):
#	if get_tree().current_scene.name == self.name && Input.is_key_pressed(KEY_ENTER):
#		_on_ConnectButton_pressed()

func _on_connection_state_changed(new_state):
	match new_state:
		0:
			# Connecting
			_connect_status_label.text = "Connecting"
		1:
			# Open
#			_connect_button.text = "Disconnect"
			_connect_status_label.text = "Connected"
		2:
			# Closing
			_connect_status_label.text = "Disconnecting"
		3:
			# Closed
#			_connect_button.text = "Connect"
			_connect_status_label.text = "Disconnected"
	var show_connect_button = new_state == 3
	var show_disconnect_button = not show_connect_button
	_connect_button.visible = show_connect_button
	_disconnect_button.visible = show_disconnect_button


func _on_ConnectButton_pressed():
	var server_info = _host_edit.text.rsplit(":", false, 1)
	var server = server_info[0]
	var port = int(server_info[1])
	brotato_client.player = _player_edit.text
	brotato_client.password = _player_edit.text
	ap_client.connect_to_multiworld(server, port)


func _on_BackButton_pressed():
	emit_signal("back_button_pressed")


func _on_DisconnectButton_pressed():
	ap_client.disconnect_from_multiworld()
