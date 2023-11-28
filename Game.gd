extends Node3D

var lobby

var unit_scene = preload("res://Unit.tscn")

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
	msg.canceled.connect(exit_game)
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
		$UI/PlayerList.text += prefix + lobby.players[id]["name"] + "\n"

# -------------------------------------------

var start = 0
var last = 0

func _process(delta):
	start += delta
	if start - last > 1.0:
		last = start
#		print(lobby.get_multiplayer_id(), "doing something")
	
	$UI/StatsLabel.text = "FPS: " + str(Performance.get_monitor(Performance.TIME_FPS)) + "\n"
	$UI/StatsLabel.text += "Process time: " + str(Performance.get_monitor(Performance.TIME_PROCESS)) + "\n"
	$UI/StatsLabel.text += "Draw calls: " + str(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)) + "\n"
	$UI/StatsLabel.text += "Unit count: " + str(len($Units.get_children())) + "\n"

@rpc("any_peer", "call_local", "reliable")
func spawn_units():
	print(lobby.get_multiplayer_id(), "spawning units")
	for i in range(100):
		var unit = unit_scene.instantiate()
		unit.position.z = randf_range(-15.0, 15.0)
		unit.position.y = 1.0
		unit.position.x = randf_range(-15.0, 15.0)
		# For now, these have server authority
		unit.set_multiplayer_authority(1)
		# unit scene needs to have replication config (select MultiplayerSynchronizer
		# & go to bottom panel to select properties for sync)
		# unit scene needs to be added to Auto Spawn list & we need to set 'true' here
		$Units.add_child(unit, true)

func _on_spawn_button_pressed():
	print(lobby.get_multiplayer_id(), "call spawn_units")
	spawn_units.rpc_id(1)
