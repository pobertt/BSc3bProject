extends Node

var Player = preload("res://scenes/player.tscn")

const port = 9999
const server_ip = "127.0.0.1"
var enet_peer = ENetMultiplayerPeer.new()

func host_game():
	print("starting host!")
	
	enet_peer.create_server(port)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	add_player(multiplayer.get_unique_id())
	
func join_game():
	print("starting join")
	
	var client_peer = enet_peer
	client_peer.create_client(server_ip, port)
	multiplayer.multiplayer_peer = client_peer

func add_player(peer_id: int):
	print("adding player %s" % peer_id)
	var player = Player.instantiate()
	player.player_id = peer_id
	player.name = str(peer_id)
	add_child(player)
	
func remove_player(peer_id: int):
	print("removed player %s" % peer_id)
