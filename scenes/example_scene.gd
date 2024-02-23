extends Node2D

## A reference to the player scene
@onready var playerScene:PackedScene = preload("res://objects/player.tscn")

func _ready() -> void:
	ServerManager.playerLoaded.rpc_id(1)
	
	# Connect the server managers signal
	ServerManager.playerDisconnected.connect(_playerDisconnected)
	ServerManager.serverDisconnected.connect(_serverDisconnected)
	
	# Let the server spawn players
	print(multiplayer.get_unique_id() )
	
	if not multiplayer.is_server():
		return
	
	var _players:Dictionary = ServerManager.players
	var _spawns:Array = %SpawnPositions.get_children()
	
	# Add players in random spawn positions
	for _id in _players:
		# Shuffles the array before picking from it
		_spawns.shuffle()
		var _spawn:Node = _spawns.pop_front()
		
		# Adds a player to our random spawn position
		playerAdd.rpc(_id, _spawn.global_position)

# WARNING This currently doesn't work if you try to start a new server!
# Issue with restarting a server without restarting the game
## Handles when the server has disconnected
func _serverDisconnected() -> void:
	get_tree().change_scene_to_file("res://server/multiplayer_menu.tscn")

## Adds a player to the server
@rpc("call_local", "reliable")
func playerAdd(id:int, pos:Vector2) -> void:
	var _player:Node = playerScene.instantiate()
	
	# Makes sure only the player with that unique id can control the player
	_player.set_multiplayer_authority(id, true)
	# Sets the players name
	_player.set_name(str(id) )
	_player.get_node("UniqueId").set_text(ServerManager.players[id].name)
	# Places the player at the given position
	_player.global_position = pos
	
	# Adds the player as a child of the "Players" node
	%Players.add_child(_player, true)

## Removes a player from the server
func _playerDisconnected(id:int) -> void:
	# Looks through all players and frees the one with the matching id
	for _child in %Players.get_children():
		if _child.name == str(id):
			_child.queue_free()
