# GameManager.gd
# Global autoload — tracks game state, torch bearer, guardian counts.
extends Node

enum GameState { MENU, PLAYING, VICTORY, GAME_OVER }

signal game_state_changed(new_state: GameState)
signal guardian_countdown_tick(seconds_left: float)

var current_state: GameState = GameState.PLAYING
var torch_bearer_id: int = 1

## Reference to the current Torch Bearer node (set on spawn / torch-pass)
var current_torch_bearer: Node3D = null
## All living players: peer_id -> Node3D
var all_players: Dictionary = {}

## Guardian countdown (GDD §7: 10-12 seconds)
const GUARDIAN_LAST_COUNTDOWN := 12.0
var _countdown_active: bool = false
var _countdown_timer: float = 0.0


func _ready() -> void:
	print("GameManager ready — Protect the Light")


func _process(delta: float) -> void:
	if _countdown_active and current_state == GameState.PLAYING:
		_countdown_timer -= delta
		guardian_countdown_tick.emit(_countdown_timer)
		if _countdown_timer <= 0.0:
			_trigger_game_over("Surrounded — all Guardians fallen.")


# ---------------------------------------------------------------------------
# Called by Player on death
# ---------------------------------------------------------------------------
func on_torch_bearer_died() -> void:
	if current_state != GameState.PLAYING:
		return
	_trigger_game_over("The Torch Bearer has fallen.")


func on_torch_extinguished() -> void:
	if current_state != GameState.PLAYING:
		return
	_trigger_game_over("The Light has gone out.")


func on_guardian_died() -> void:
	if current_state != GameState.PLAYING:
		return
	# Check if any guardian remains
	var guardians_alive := false
	for id in all_players:
		var p := all_players[id] as Node3D
		if not is_instance_valid(p):
			continue
		if p == current_torch_bearer:
			continue
		var hc := p.get_node_or_null("HealthComponent")
		if hc and hc.is_alive():
			guardians_alive = true
			break

	if not guardians_alive:
		_start_guardian_countdown()


func on_reach_destination() -> void:
	if current_state != GameState.PLAYING:
		return
	current_state = GameState.VICTORY
	game_state_changed.emit(current_state)
	print("VICTORY — The Light is safe!")


# ---------------------------------------------------------------------------
# Torch bearer management
# ---------------------------------------------------------------------------
func get_torch_bearer() -> Node3D:
	return current_torch_bearer


func set_torch_bearer(player: Node3D) -> void:
	current_torch_bearer = player


func register_player(peer_id: int, player: Node3D) -> void:
	all_players[peer_id] = player
	if all_players.size() == 1:
		# First player is always Torch Bearer
		current_torch_bearer = player


func unregister_player(peer_id: int) -> void:
	all_players.erase(peer_id)


# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------
func _start_guardian_countdown() -> void:
	if _countdown_active:
		return
	_countdown_active = true
	_countdown_timer = GUARDIAN_LAST_COUNTDOWN
	print("Last Guardian down! Countdown started...")


func cancel_countdown() -> void:
	_countdown_active = false
	_countdown_timer = 0.0


func _trigger_game_over(reason: String) -> void:
	if current_state != GameState.PLAYING:
		return
	current_state = GameState.GAME_OVER
	game_state_changed.emit(current_state)
	print("GAME OVER: ", reason)
