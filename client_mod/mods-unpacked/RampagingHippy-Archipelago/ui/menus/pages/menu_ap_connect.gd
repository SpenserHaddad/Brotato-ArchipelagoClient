extends MarginContainer

signal back_button_pressed

const _AP_PLAYER_SESSION_NS = preload ("res://mods-unpacked/RampagingHippy-Archipelago/singletons/ap_player_session.gd")

var _ap_icon_connected = preload ("res://mods-unpacked/RampagingHippy-Archipelago/ap_button_icon_connected.png")
var _ap_icon_disconnected = preload ("res://mods-unpacked/RampagingHippy-Archipelago/ap_button_icon_disconnected.png")
var _ap_icon_error = preload ("res://mods-unpacked/RampagingHippy-Archipelago/ap_button_icon_error.png")

onready var _connect_button: Button = $"VBoxContainer/ConnectButton"
onready var _disconnect_button: Button = $"VBoxContainer/DisconnectButton"
onready var _connect_status_label: Label = $"VBoxContainer/ConnectStatusLabel"
onready var _connect_error_label: Label = $"VBoxContainer/ConnectionErrorLabel"
onready var _host_edit: LineEdit = $"VBoxContainer/CenterContainer/GridContainer/HostEdit"
onready var _player_edit: LineEdit = $"VBoxContainer/CenterContainer/GridContainer/PlayerEdit"
onready var _password_edit: LineEdit = $"VBoxContainer/CenterContainer/GridContainer/PasswordEdit"
onready var _status_texture: TextureRect = $"VBoxContainer/StatusTexture"

onready var _ap_session

const _MAX_ANGLE_DEGREES = 360
const _STATUS_TEXTURE_ROTATION_SPEED_DEGREES_PER_SECOND = 360
var _animate_status_texture: bool = false

func init():
	# Needed to make the scene switch in title_screen_menus happy.
	pass

func _ready():
	var mod_node = get_node("/root/ModLoader/RampagingHippy-Archipelago")
	
	_ap_session = mod_node.ap_player_session
	_ap_session.connect("connection_state_changed", self, "_on_connection_state_changed")

#func _input(_event):
#	if get_tree().current_scene.name == self.name && Input.is_key_pressed(KEY_ENTER):
#		_on_ConnectButton_pressed()

func _on_connection_state_changed(new_state: int, error: int=0):
	# Break out ApPlayerSession.ConnectState so we have a shorter name
	var ConnectState = _AP_PLAYER_SESSION_NS.ConnectState
	# See ConnectState enum in ap_player_session.gd
	match new_state:
		ConnectState.DISCONNECTED:
			# Disconnected
			_connect_status_label.text = "Disconnected"
		ConnectState.CONNECTING:
			# Connecting
			_connect_status_label.text = "Connecting"
		ConnectState.DISCONNECTING:
			# Disconnecting
			_connect_status_label.text = "Disconnecting"
		ConnectState.CONNECTED_TO_SERVER:
			# Connected to server
			_connect_status_label.text = "Connected to server"
		ConnectState.CONNECTED_TO_MULTIWORLD:
			# Connected to multiworld
			_connect_status_label.text = "Connected to multiworld"

	# Allow connecting if disconnected or connected to the server but not the multiworld
	_connect_button.disabled = (
		new_state == ConnectState.CONNECTED_TO_MULTIWORLD or
		new_state == ConnectState.DISCONNECTING
	)
	if _connect_button.disabled and _connect_button.has_focus():
		# Disabled buttons having focus look ugly and don't make sense.
		_connect_button.release_focus()

	# Allow disconnecting if connected to the server and/or multiworld
	_disconnect_button.disabled = (
		new_state == ConnectState.DISCONNECTED or
		new_state == ConnectState.DISCONNECTED or
		 # TODO: Remove below if we figure out how to cancel the connection process.
		new_state == ConnectState.CONNECTING
	)

	if _disconnect_button.disabled and _disconnect_button.has_focus():
		_disconnect_button.release_focus()

	if new_state == ConnectState.CONNECTED_TO_MULTIWORLD:
		_status_texture.texture = _ap_icon_connected
	elif error != 0:
		_status_texture.texture = _ap_icon_error
	else:
		_status_texture.texture = _ap_icon_disconnected
		
	if new_state == ConnectState.CONNECTING:
		_animate_status_texture = true
	else:
		_animate_status_texture = false
		_status_texture.rect_rotation = 0
	
	if error != 0:
		_set_error(error)
	else:
		_clear_error()

func _set_error(error_reason: int):
	# See ConnectResult enum in ap_player_session.gd
	var ConnectResult = _AP_PLAYER_SESSION_NS.ConnectResult
	var error_text: String
	match error_reason:
		ConnectResult.SERVER_CONNECT_FAILURE:
			error_text = "Failed to connect to the server"
		ConnectResult.PLAYER_NOT_SET:
			error_text = "Need to set player name before connecting"
		ConnectResult.GAME_NOT_SET:
			error_text = "Client needs to set game name before connecting"
		ConnectResult.INVALID_SERVER:
			error_text = "Invalid server name"
		ConnectResult.AP_INVALID_SLOT:
			error_text = "AP: Invalid player name"
		ConnectResult.AP_INVALID_GAME:
			error_text = "AP: Invalid game"
		ConnectResult.AP_INCOMPATIBLE_VERSION:
			error_text = "AP: Incompatible versions"
		ConnectResult.AP_INVALID_PASSWORD:
			error_text = "AP: Invalid or missing password"
		ConnectResult.AP_INVALID_ITEMS_HANDLING:
			error_text = "AP: Invalid items handling"
		ConnectResult.AP_CONNECTION_REFUSED_UNKNOWN_REASON:
			error_text = "AP: Failed to connect (unknown error)"
		_:
			error_text = "Unknown error"

	_connect_error_label.visible = true
	_connect_error_label.text = error_text

func _clear_error():
	_connect_error_label.visible = false
	_connect_error_label.text = ""

func _on_ConnectButton_pressed():
	_ap_session.server = _host_edit.text
	_ap_session.player = _player_edit.text
 
	# Fire and forget this coroutine call, signal handlers will take care of the rest.
	_ap_session.connect_to_multiworld(_password_edit.text)

func _on_BackButton_pressed():
	emit_signal("back_button_pressed")

func _on_DisconnectButton_pressed():
	_ap_session.disconnect_from_multiworld()

func _reset_status_texture():
	_status_texture.set_rotation(0)

func _process(delta):
	if _animate_status_texture:
		# Set status texture to pivot around its center instead of its top-left corner.
		# Do this every frame in case the screen size changes.
		_status_texture.rect_pivot_offset = _status_texture.rect_size / 2
		var new_angle = _status_texture.rect_rotation + (delta * _STATUS_TEXTURE_ROTATION_SPEED_DEGREES_PER_SECOND)
		if new_angle > _MAX_ANGLE_DEGREES:
			# Rotation goes from -360 to 360 degrees
			new_angle -= _MAX_ANGLE_DEGREES * 2
		_status_texture.rect_rotation = new_angle
