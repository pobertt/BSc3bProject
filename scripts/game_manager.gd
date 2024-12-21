extends Node

@onready var main_menu: Control = $"../main_menu"


#signals for join and host game buttons, maybe move this out into a seperate ui script??
func host_game():
	print("host button pressed")
	main_menu.hide()
	# Calling autoload script.
	MultiplayerManager.host_game()
	
func join_game():
	print("join button pressed")
	main_menu.hide()
	MultiplayerManager.join_game()
