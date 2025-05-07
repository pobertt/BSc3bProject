extends Node

# Loading scenes:
var player_scene = preload("res://scenes/player.tscn")
var obj_scene = preload("res://scenes/objects/object.tscn")

# Open Port number and IP address for clients
const port = 9999
var server_ip = "" #127.0.0.1 and use host buttons for debug purposes and when cloud server is on do amazon link like: "ec2-51-20-120-25.eu-north-1.compute.amazonaws.com".0

# Created MultiplayerPeer object
var enet_peer = ENetMultiplayerPeer.new()

var players_spawn_node
var obj_spawn_node

# Array of colours for the Players: Player 1 = RED, Player 2 = BLUE and so on
@export var color : Array = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.PURPLE, Color.ORANGE, Color.BLACK, Color.WHITE]
var color_id = 0

func host_game() -> void:
	print("starting host!")
	
	# Grabbing the player_spawn from the world.tscn
	players_spawn_node = get_tree().get_current_scene().get_node("player_spawn")
	
	# Needs to be an array of objects for different spawn positions
	obj_spawn_node = get_tree().get_current_scene().get_node("object_spawn")
	
	# Create server
	enet_peer.set_bind_ip(server_ip)
	enet_peer.create_server(port)
	
	multiplayer.multiplayer_peer = enet_peer
	
	
	# Connecting add_player() and remove_player() functions for peer connected/disconnected signals
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	# Spawning a multiplayer object in the world
	obj_spawn()
	
	# Adding player with the unique ID associated to that peer
	if not OS.has_feature("dedicated_server"):
		add_player(multiplayer.get_unique_id())

func join_game() -> void:
	print("starting join")
	
	# Create client
	var client_peer = enet_peer
	print("MultiplayerManager Join Game: ", server_ip)
	client_peer.create_client(server_ip, port)
	multiplayer.multiplayer_peer = client_peer

func add_player(peer_id: int):
	print("adding player %s" % peer_id)
	
	# Adding new player into the game world
	var player = player_scene.instantiate()
	player.player_id = peer_id
	player.name = str(peer_id)
	
	# Spawn location
	players_spawn_node.add_child(player)

# Removing player from game world on disconnect
func remove_player(peer_id: int):
	print("removed player %s" % peer_id)
	
	var player = get_node_or_null(str(peer_id))
	if player:
		player.robot_mat.hide()
		player.queue_free()

@rpc("call_local")
func set_colour(player):
	# Updating players colours
	
	var colour = color[color_id] as Color
	player.robot_mat.duplicate()
	player.robot_mat.albedo_color = colour
	player.robot.set_surface_override_material(0, player.robot_mat)
	color_id = color_id + 1

# Object spawning
func obj_spawn():
	var test_obj = obj_scene.instantiate()
	obj_spawn_node.add_child(test_obj)
