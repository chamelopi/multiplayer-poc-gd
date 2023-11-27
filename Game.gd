extends Node3D

var lobby

func _ready():
	# Let lobby know that we finished loading
	lobby = get_tree().get_root().get_node("LobbyContainer")
	lobby.player_loaded.rpc_id(1)
	# Stop main loop until everyone has loaded into the game
	get_tree().set_pause(true)
	
	print("_ready() called for ", lobby.get_multiplayer_id())
	
	if multiplayer.is_server():
		lobby.player_connected.connect(func(): fill_lobby_list.rpc())
		lobby.player_disconnected.connect(func(): fill_lobby_list.rpc())
	else:
		lobby.server_disconnected.connect(show_disconnect_msg)
	
func show_disconnect_msg():
	var msg = AcceptDialog.new()
	msg.dialog_text = "Disconnected from server! Exiting game..."
	msg.confirmed.connect(exit_game)
	add_child(msg)
	msg.show()
	
func exit_game():
	print("exiting...")
	get_tree().quit()

func start_game():
	print("all players connected, starting game!")
	fill_lobby_list.rpc()
	
@rpc("authority", "call_local", "reliable")
func fill_lobby_list():
	# Has to be done in an rpc to reach every player :)
	get_tree().set_pause(false)
	for id in lobby.players:
		var prefix = "(me) " if id == lobby.get_multiplayer_id() else ""
		$PlayerList.text += prefix + lobby.players[id]["name"] + "\n"

# -------------------------------------------

var start = 0
var last = 0

func _process(delta):
	start += delta
	if start - last > 1.0:
		last = start
		print(lobby.get_multiplayer_id(), "doing something")
