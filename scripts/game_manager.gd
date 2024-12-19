extends Node

@onready var multiplayer_hud: Control = $"../multiplayerHUD"

#signals for join and host game buttons, maybe move this out into a seperate ui script??
func host_game():
	print("host button pressed")
	multiplayer_hud.hide()
	#Calling autoload script
	MultiplayerManager.host_game()
	
func join_game():
	print("join button pressed")
	multiplayer_hud.hide()
	MultiplayerManager.join_game()
