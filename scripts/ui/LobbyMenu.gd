# LobbyMenu.gd
# Main Menu & Multiplayer Co-op Lobby (GDD §1, §14)
extends Control

@onready var solo_btn: Button = $VBox/SoloBtn
@onready var host_btn: Button = $VBox/HostBtn
@onready var join_btn: Button = $VBox/HBoxJoin/JoinBtn
@onready var ip_input: LineEdit = $VBox/HBoxJoin/IpInput
@onready var status_label: Label = $VBox/StatusLabel
@onready var start_btn: Button = $VBox/StartBtn

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	solo_btn.pressed.connect(_on_solo_pressed)
	host_btn.pressed.connect(_on_host_pressed)
	join_btn.pressed.connect(_on_join_pressed)
	start_btn.pressed.connect(_on_start_pressed)

	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.connection_succeeded.connect(_on_connection_succeeded)
	NetworkManager.connection_failed.connect(_on_connection_failed)

func _on_solo_pressed() -> void:
	status_label.text = "Starting Solo Expedition as Torch Bearer..."
	NetworkManager.leave_game()
	NetworkManager.start_game()

func _on_host_pressed() -> void:
	var err := NetworkManager.host_game()
	if err == OK:
		status_label.text = "Hosting Server on port 7777. You are Torch Bearer (P1)."
		host_btn.disabled = true
		join_btn.disabled = true
		start_btn.visible = true
	else:
		status_label.text = "Failed to host server: %s" % error_string(err)

func _on_join_pressed() -> void:
	var ip := ip_input.text.strip_edges()
	if ip.is_empty():
		ip = "127.0.0.1"
	status_label.text = "Connecting to %s..." % ip
	var err := NetworkManager.join_game(ip)
	if err == OK:
		host_btn.disabled = true
		join_btn.disabled = true
	else:
		status_label.text = "Failed to connect: %s" % error_string(err)

func _on_player_connected(id: int) -> void:
	status_label.text = "Player %d joined! Total: %d/4" % [id, NetworkManager.players.size()]

func _on_connection_succeeded() -> void:
	status_label.text = "Connected to Host! You are Guardian. Waiting for Host to start..."

func _on_connection_failed() -> void:
	status_label.text = "Connection failed. Please check IP."
	host_btn.disabled = false
	join_btn.disabled = false

func _on_start_pressed() -> void:
	status_label.text = "Departing into the Dark..."
	NetworkManager.start_game()