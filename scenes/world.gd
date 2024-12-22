extends Node

@onready var main_menu: CanvasLayer = $main_menu

var Player = preload("res://scenes/player.tscn")

const port = 9999
const server_ip = "127.0.0.1"
var enet_peer = ENetMultiplayerPeer.new()

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

func _on_host_game_pressed() -> void:
	print("starting host!")
	main_menu.hide()
	
	enet_peer.create_server(port)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	add_player(multiplayer.get_unique_id())

func add_player(peer_id: int):
	print("adding player %s" % peer_id)
	var player = Player.instantiate()
	player.player_id = peer_id
	player.name = str(peer_id)
	add_child(player)

func remove_player(peer_id: int):
	print("removed player %s" % peer_id)
