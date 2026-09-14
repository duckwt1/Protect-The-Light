# NetworkManager.gd
# Autoload singleton – handles hosting / joining and player spawning
extends Node

const PORT := 7777
const MAX_PLAYERS := 4

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal connection_succeeded
signal connection_failed
signal server_disconnected

var players: Dictionary = {}  # peer_id -> player_info

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func host_game() -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_PLAYERS)
	if err != OK:
		push_error("Failed to create server: %s" % error_string(err))
		return err
	multiplayer.multiplayer_peer = peer
	# Server is also a player (id = 1)
	players[1] = {"name": "Host"}
	player_connected.emit(1)
	print("Server started on port ", PORT)
	return OK


func join_game(ip: String = "127.0.0.1") -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, PORT)
	if err != OK:
		push_error("Failed to create client: %s" % error_string(err))
		return err
	multiplayer.multiplayer_peer = peer
	print("Connecting to ", ip)
	return OK


func leave_game() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players.clear()


func _on_peer_connected(id: int) -> void:
	print("Peer connected: ", id)
	players[id] = {"name": "Player %d" % id}
	player_connected.emit(id)


func _on_peer_disconnected(id: int) -> void:
	print("Peer disconnected: ", id)
	players.erase(id)
	player_disconnected.emit(id)


func _on_connected_to_server() -> void:
	print("Successfully connected to server")
	connection_succeeded.emit()


func _on_connection_failed() -> void:
	print("Connection failed")
	connection_failed.emit()


func _on_server_disconnected() -> void:
	print("Server disconnected")
	players.clear()
	server_disconnected.emit()
