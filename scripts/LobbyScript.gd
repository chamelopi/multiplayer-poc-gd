extends GridContainer

# These signals can be connected to by a UI lobby scene or the game scene.
signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

const MAX_CONNECTIONS = 20
var port: int
var server_ip: int

# This will contain player info for every player,
# with the keys being each player's unique IDs.
var players = {}
var players_loaded = 0

# This is the local player info. This should be modified locally
# before the connection is made. It will be passed to every other peer.
# For example, the value of "name" can be set to something the player
# entered in a UI scene.
var player_info = {"name": "Name"}

# Called when the node enters the scene tree for the first time.
func _ready():
	# Hook up signals
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# Joins an existing game
func join_game(address = "localhost", port = 1337):
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	
# Hosts a game
func create_game(port = 1337):
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, MAX_CONNECTIONS)
	if error:
		return error
	multiplayer.multiplayer_peer = peer

	players[1] = player_info
	player_connected.emit(1, player_info)

func remove_multiplayer_peer():
	multiplayer.multiplayer_peer = null
	
func get_multiplayer_id():
	if multiplayer.multiplayer_peer:
		return multiplayer.multiplayer_peer.get_unique_id()
	else:
		return 0
	
# When the server decides to start the game from a UI scene,
# do Lobby.load_game.rpc(filepath)
@rpc("call_local", "reliable")
func load_game(game_scene_path):
	var world = load(game_scene_path).instantiate()
	get_tree().get_root().add_child(world)
	get_tree().get_root().get_node("LobbyContainer").hide()
	
# Every peer will call this when they have loaded the game scene.
@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	if multiplayer.is_server():
		players_loaded += 1
		# In the future we will want to pre-load some stuff here & ensure that
		# all players in the lobby have done that instead
		if players_loaded == players.size():
			$/root/Game.start_game()
			players_loaded = 0
			

# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_player_connected(id):
	print("Player with id " + str(id) + " connected")
	_register_player.rpc_id(id, player_info)
	
@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)

func _on_player_disconnected(id):
	print("Player with id " + str(id) + " disconnected")
	players.erase(id)
	player_disconnected.emit(id)


func _on_connected_ok():
	var peer_id = multiplayer.get_unique_id()
	print("Connected successfully, peer_id is " + str(peer_id))
	players[peer_id] = player_info
	player_connected.emit(peer_id, player_info)


func _on_connected_fail():
	# TODO: Better error handling
	print("Cannot connect!")
	multiplayer.multiplayer_peer = null


func _on_server_disconnected():
	print("Server disconnected!")
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()
	
# ------------------------------------------------------------------------------

func validate_input():
	if len($NameEdit.text) < 3:
		print("empty name!")
		return

func _on_connect_button_pressed():
	validate_input()
	
	player_info = { "name": $NameEdit.text }
	# TODO: input validation
	join_game($HostEdit.text, int($PortEdit.text))
	$ConnectButton.hide()
	$HostButton.hide()


func _on_host_button_pressed():
	validate_input()
	
	player_info = { "name": $NameEdit.text }
	# TODO: input validation
	create_game(int($PortEdit.text))
	$ConnectButton.hide()
	$HostButton.hide()
	$StartButton.show()


func _on_start_button_pressed():
	load_game.rpc("res://scenes/MainScene.tscn")
