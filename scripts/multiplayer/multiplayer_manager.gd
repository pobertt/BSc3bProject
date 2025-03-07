extends Node

var player_scene = preload("res://scenes/player.tscn")

const port = 9999
const server_ip = "127.0.0.1" #127.0.0.1 and use host buttons for debug purposes and when cloud server is on do amazon link like: "ec2-51-20-120-25.eu-north-1.compute.amazonaws.com"
# https://docs.google.com/document/d/1X4IDBqv88DmRfyXRnI6NJx0-Duj_UsSrP9up_GclNuc/edit?tab=t.0

var enet_peer = ENetMultiplayerPeer.new()

var players_spawn_node

@export var color : Array = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.PURPLE, Color.ORANGE, Color.BLACK, Color.WHITE]
var color_id = 0

func host_game() -> void:
	print("starting host!")
	
	# Grabbing the player_spawn from the world.tscn
	players_spawn_node = get_tree().get_current_scene().get_node("player_spawn")
	
	enet_peer.create_server(port)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	if not OS.has_feature("dedicated_server"):
		add_player(multiplayer.get_unique_id())

func join_game() -> void:
	print("starting join")
	
	var client_peer = enet_peer
	client_peer.create_client(server_ip, port)
	multiplayer.multiplayer_peer = client_peer

func add_player(peer_id: int):
	print("adding player %s" % peer_id)
	var player = player_scene.instantiate()
	player.player_id = peer_id
	player.name = str(peer_id)
	
	players_spawn_node.add_child(player)

func remove_player(peer_id: int):
	print("removed player %s" % peer_id)
	
	var player = get_node_or_null(str(peer_id))
	#player.position = Vector3(0,50,0)
	if player:
		player.robot_mat.hide()
		player.queue_free()

@rpc("call_local")
func set_colour(player):
	var colour = color[color_id] as Color
	player.robot_mat.duplicate()
	player.robot_mat.albedo_color = colour
	player.robot.set_surface_override_material(0, player.robot_mat)
	color_id = color_id + 1
