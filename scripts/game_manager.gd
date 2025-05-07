extends Node

@onready var main_menu: Control = $"../CanvasLayer/main_menu"
@export var ip: LineEdit

# Runs when server starts.
func _ready():
	if OS.has_feature("dedicated_server"):
		print("Starting dedicated server...")
		MultiplayerManager.server_ip = ip.text
		MultiplayerManager.host_game()

# Signals for host and join game buttons .
# Host button/function enabled during debug phase.
func host_game():
	print("host button pressed")
	main_menu.hide()
	# Calling autoload script.
	MultiplayerManager.server_ip = ip.text
	print(MultiplayerManager.server_ip)
	MultiplayerManager.host_game()
	
func join_game():
	print("join button pressed")
	main_menu.hide()
	MultiplayerManager.server_ip = ip.text
	MultiplayerManager.join_game()
