extends Control

func _ready() -> void:
	# Connect server signals to local functions
	ServerManager.playerConnected.connect(_playerConnected)
	ServerManager.playerDisconnected.connect(_playerDisconnected)
	
	# Server tab signals
	%ServerCreate.pressed.connect(_serverCreate)
	%ServerJoin.pressed.connect(_serverJoin)
	%ServerEndedBack.pressed.connect(func():
		%Menu.set_current_tab(0)
	)
	
	# Lobby tab signals
	%LobbyStart.pressed.connect(_lobbyStart)
	%LobbyLeave.pressed.connect(_lobbyLeave)

#region Server Signal Functions
## Creates a server
func _serverCreate() -> void:
	# Set the local players name
	ServerManager.playerInfo.name = %ServerPlayerName.text
	
	# Attempt to create a new server
	var _error := ServerManager.serverCreate()
	if _error: return
	
	# Connect server disconnect signal to our host disconnection function
	ServerManager.serverDisconnected.connect(_serverHostDisconnected)
	
	# Switch to the lobby menu
	%Menu.set_current_tab(1)
	%LobbyStart.set_disabled(false)

## Joins an existing server
func _serverJoin() -> void:
	# Set the local players name
	ServerManager.playerInfo.name = %ServerPlayerName.text
	
	# Attempt to join an existing server
	var _error := ServerManager.serverJoin()
	if _error: return
	
	# Wait till we've connected to continue
	await multiplayer.connected_to_server
	
	# Connect server disconnect signal to our peer disconnection function
	ServerManager.serverDisconnected.connect(_serverPeerDisconnected)
	
	# Switch to the lobby menu
	%Menu.set_current_tab(1)

## Called on the server when they've disconnected
func _serverHostDisconnected() -> void:
	# Disconnect from the server disconnect signal
	ServerManager.serverDisconnected.disconnect(_serverHostDisconnected)
	%Menu.set_current_tab(0)

## Called on peers when the host has disconnected
func _serverPeerDisconnected() -> void:
	# Disconnect from the server disconnect signal
	ServerManager.serverDisconnected.disconnect(_serverPeerDisconnected)
	%Menu.set_current_tab(2)

## Adds a players name to the lobby player list
func _playerConnected(id:int, info:Dictionary) -> void:
	lobbyPlayerListUpdate()

## Removes a players name from the lobby player list
func _playerDisconnected(id:int) -> void:
	lobbyPlayerListUpdate()
#endregion

#region Lobby Functions
func _lobbyStart() -> void:
	ServerManager.loadScene.rpc("res://scenes/example_scene.tscn")

## Leaves the current lobby
func _lobbyLeave() -> void:
	# Close the multiplayer peer
	ServerManager.serverClose()
	%Menu.set_current_tab(0)

## Updates the player list names in the server
func lobbyPlayerListUpdate() -> void:
	# Remove all names from the lobby player list
	for child in %PlayerListContainer.get_children():
		child.queue_free()
	
	# Add each player name into the lobby player list
	for _id in ServerManager.players:
		# Create a new label for the player
		var _label := Label.new()
		_label.set_name(str(_id) )
		_label.set_text(ServerManager.players[_id].name)
		_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
		
		# Display the server hosts name
		if _id == 1:
			%LobbyHostName.set_text(ServerManager.players[_id].name + "'s Server")
		
		# Add the label to the player list
		%PlayerListContainer.add_child(_label)
#endregion
