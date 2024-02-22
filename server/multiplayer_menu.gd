extends Control

func _ready() -> void:
	# Connect server signals to local functions
	ServerManager.playerConnected.connect(_playerConnected)
	ServerManager.playerDisconnected.connect(_playerDisconnected)
	ServerManager.serverDisconnected.connect(_serverDisconnected)
	
	# Server tab signals
	%ServerCreate.pressed.connect(_serverCreate)
	%ServerJoin.pressed.connect(_serverJoin)
	
	# Lobby tab signals
	%LobbyLeave.pressed.connect(_lobbyLeave)
	
	# Server ended tab signals
	%ServerEndedBack.pressed.connect(func():
		%Menu.set_current_tab(0)
	)

#region Server Signal Functions
## Creates a server
func _serverCreate() -> void:
	# Set the local players name
	ServerManager.playerInfo.name = %ServerPlayerName.text
	# Create a new server
	ServerManager.serverCreate()
	# Switch to the lobby menu
	%Menu.set_current_tab(1)
	%LobbyStart.set_disabled(false)

## Joins an existing server
func _serverJoin() -> void:
	# Set the local players name
	ServerManager.playerInfo.name = %ServerPlayerName.text
	# Join an existing server
	ServerManager.serverJoin()
	# Switch to the lobby menu
	%Menu.set_current_tab(1)

## Called when the server host has disconnected
func _serverDisconnected() -> void:
	%Menu.set_current_tab(2)

## Adds a players name to the lobby player list
func _playerConnected(id:int, info:Dictionary) -> void:
	lobbyPlayerListUpdate()

## Removes a players name from the lobby player list
func _playerDisconnected(id:int) -> void:
	lobbyPlayerListUpdate()
#endregion

#region Lobby Functions
## Leaves the current lobby
func _lobbyLeave() -> void:
	ServerManager.serverLeave()
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
