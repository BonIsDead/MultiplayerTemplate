extends Node

## Emitted when a player connects
signal playerConnected(id:int, info:Dictionary)
## Emitted when a player disconnects
signal playerDisconnected(id:int)
## Emitted when the sever disconnects
signal serverDisconnected

## The port to connect to
const PORT:int = 7000
## The fallback IP to connect to
const IP_DEFAULT:String = "127.0.0.1"
## Maximum connections allowed in the server
const CONNECTIONS_MAX:int = 4

## Contains information on all players with keys being unique IDs
var players:Dictionary
## How many players have successfully loaded
var playersLoaded:int

## The local player information
var playerInfo:Dictionary = {
	"name" : "???"
}

var serverSeed:int = randi()

func _ready() -> void:
	# Connect all multiplayer signals to our multiplayer functions
	multiplayer.peer_connected.connect(_playerConnected)
	multiplayer.peer_disconnected.connect(_playerDisconnected)
	multiplayer.connected_to_server.connect(_serverConnected)
	multiplayer.connection_failed.connect(_serverConnectionFailed)
	multiplayer.server_disconnected.connect(_serverDisconnected)

#region Server/Client Creation
## Creates a server
func serverCreate() -> Error:
	# Create a multiplayer server
	var _peer := ENetMultiplayerPeer.new()
	var _error := _peer.create_server(PORT, CONNECTIONS_MAX)
	
	# Check if server creation was successful
	if _error:
		match(_error):
			# If server creation has failed
			ERR_CANT_CREATE:
				printerr("Failed to create server: ", _error)
				return _error
			
			# If the error was something unexpected
			_:
				printerr("Something went wrong: ", _error)
				return _error
	
	# Set the peer to our new multiplayer peer
	multiplayer.multiplayer_peer = _peer
	
	# Add local player information
	players[1] = playerInfo
	playerConnected.emit(1, playerInfo)
	
	return OK

## Joins an existing server
func serverJoin(address:String = "") -> Error:
	# Set the address to the default if nothing was entered
	if address.is_empty():
		address = IP_DEFAULT
	
	# Create a multiplayer client
	var _peer := ENetMultiplayerPeer.new()
	var _error := _peer.create_client(address, PORT)
	
	# Check if client creation was successful
	if _error:
		match(_error):
			# If a connection already exists on the port we're using
			ERR_ALREADY_EXISTS:
				printerr("A connection already exists on that port: ", _error)
				return _error
			
			# If we failed to connect to an existing server
			ERR_CANT_CONNECT:
				printerr("Failed to connect to game: ", _error)
				return _error
			
			# If the error was something unexpected
			_:
				printerr("Something went wrong: ", _error)
				return _error
	
	# Set the peer to our new multiplayer peer
	multiplayer.multiplayer_peer = _peer
	return OK

## Closes the server
func serverClose() -> void:
	# Close the multiplayer peer
	multiplayer.multiplayer_peer.close()
	# Set the multiplayer API back to default (so players can create/join a server without having to reopen the game)
	get_tree().set_multiplayer(MultiplayerAPI.create_default_interface() )
	# Reset the players dictionary
	players.clear()

## Sets the random seed for the server
@rpc("call_remote", "authority", "reliable")
func serverSetRandomSeed(value:int) -> void:
	serverSeed = value
	seed(value)
#endregion

## Called to change the scene
@rpc("call_local", "reliable")
func loadScene(path:String) -> void:
	get_tree().change_scene_to_file(path)

#region Player Functions
## Registers the player to the "players" dictionary
@rpc("any_peer", "reliable")
func _playerRegister(info:Dictionary) -> void:
	var _id:int = multiplayer.get_remote_sender_id()
	players[_id] = info
	playerConnected.emit(_id, info)

@rpc("any_peer", "call_local", "reliable")
func playerLoaded() -> void:
	# Check if we're the server
	if not multiplayer.is_server():
		return
	
	# Incriment the loaded players count
	playersLoaded += 1
	
	# Check if the players loaded is the same as the amount of players
	if not playersLoaded == players.size():
		return
	
	print(playersLoaded)
	playersLoaded = 0
#endregion

#region Signal Functions
## Sends player information to peers on connection
func _playerConnected(id:int) -> void:
	_playerRegister.rpc_id(id, playerInfo)
	
	# Syncs the random seed for each client
	if multiplayer.is_server():
		serverSetRandomSeed.rpc_id(id, serverSeed)

## Removes the player from the server
func _playerDisconnected(id:int) -> void:
	players.erase(id)
	playerDisconnected.emit(id)

## Adds player information to the server on connection
func _serverConnected() -> void:
	var _id:int = multiplayer.get_unique_id()
	players[_id] = playerInfo
	playerConnected.emit(_id, playerInfo)

## If connection to the server has failed
func _serverConnectionFailed() -> void:
	multiplayer.multiplayer_peer = null
	printerr("Failed to connect to server.")

## Alerts that the server has been disconnected
func _serverDisconnected() -> void:
	multiplayer.multiplayer_peer = null
	
	players.clear()
	serverDisconnected.emit()
#endregion
