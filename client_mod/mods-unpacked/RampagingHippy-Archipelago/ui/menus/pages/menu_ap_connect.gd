extends MarginContainer

signal back_button_pressed

onready var _connect_button: Button = $"VBoxContainer/ConnectButton"
onready var _disconnect_button: Button = $"VBoxContainer/DisconnectButton"
onready var _connect_status_label: Label = $"VBoxContainer/ConnectStatusLabel"
onready var _connect_error_label: Label = $"VBoxContainer/ConnectionErrorLabel"
onready var _host_edit: LineEdit = $"VBoxContainer/CenterContainer/GridContainer/HostEdit"
onready var _player_edit: LineEdit = $"VBoxContainer/CenterContainer/GridContainer/PlayerEdit"
onready var _password_edit: LineEdit = $"VBoxContainer/CenterContainer/GridContainer/PasswordEdit"

onready var _ap_websocket_connection
onready var _ap_client

func init():
	# Needed to make the scene switch in title_screen_menus happy.
	pass

func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	_ap_websocket_connection = mod_node.ap_websocket_connection
	_ap_client = mod_node.brotato_ap_client
	_ap_websocket_connection.connect("connection_state_changed", self, "_on_connection_state_changed")
	_ap_client.connect("on_connection_refused", self, "_on_connection_refused")
	_on_connection_state_changed(_ap_websocket_connection.connection_state)

#func _input(_event):
#	if get_tree().current_scene.name == self.name && Input.is_key_pressed(KEY_ENTER):
#		_on_ConnectButton_pressed()

func _on_connection_state_changed(new_state, connection_refused: bool = false):
	match new_state:
		0:
			# Connecting
			_connect_status_label.text = "Connecting"
		1:
			# Open
			_connect_status_label.text = "Connected"
		2:
			# Closing
			_connect_status_label.text = "Disconnecting"
		3:
			# Closed
#			_connect_button.text = "Connect"
			_connect_status_label.text = "Disconnected"
	var show_connect_button = new_state == 3 or (new_state == 1 and connection_refused)
	var show_disconnect_button = not show_connect_button
	_connect_button.visible = show_connect_button
	_disconnect_button.visible = show_disconnect_button
	# _connect_error_label.visible = show_disconnect_button

func _on_connection_refused(reasons: Array):
	#TODO: handle multiple errors
	var reason_string
	match reasons[0]:
		"InvalidSlot":
			reason_string = "Invalid slot: %s." % _ap_client.player
		"InvalidGame":
			reason_string = "Slot for %s is not a Brotato game." % _ap_client.player
		"IncompatibleVersion":
			reason_string = "Version mismatch."
		"InvalidPassword":
			reason_string = "Invalid password."
		"InvalidItemsHandling":
			reason_string = "Invalid items handling (oops)."
	_connect_error_label.text = "Connection Refused: " + reason_string
	# _on_connection_state_changed(1, true)
	

func _on_ConnectButton_pressed():
	var url = _host_edit.text
	_ap_client.player = _player_edit.text
	_ap_client.password = _password_edit.text
	_ap_websocket_connection.connect_to_multiworld(url)


func _on_BackButton_pressed():
	emit_signal("back_button_pressed")


func _on_DisconnectButton_pressed():
	_ap_websocket_connection.disconnect_from_multiworld()
