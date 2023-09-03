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

func _input(_event):
	if Input.is_key_pressed(KEY_ENTER):
		_on_ConnectButton_pressed()

func _on_ConnectButton_pressed():
	var log_message = "Would connect with Host='{host}', Player='{player}', Password='{password}'".format(
		{"host": _host_edit.text, 
		"player": _player_edit.text,
		"password": _password_edit.text
	})
	ModLoaderLog.info(log_message, ArchipelagoModBase.MOD_NAME)
	emit_signal("connect_button_pressed")