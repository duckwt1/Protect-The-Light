# HUD.gd
# Overlay UI: HP, Torch durability, zone label, journey %, warning vignette,
# interaction bar, and Game Over / Victory panels.
extends CanvasLayer

@onready var health_bar: ProgressBar  = $BottomLeft/HealthBar
@onready var torch_bar: ProgressBar   = $BottomLeft/TorchBar
@onready var alive_label: Label       = $BottomLeft/AliveLabel
@onready var bearer_label: Label      = $BearerLabel
@onready var zone_label: Label        = $ZoneLabel
@onready var vignette: ColorRect      = $WarningVignette
@onready var interact_container: VBoxContainer = $InteractionContainer
@onready var interact_bar: ProgressBar         = $InteractionContainer/InteractionBar
@onready var interact_label: Label             = $InteractionContainer/InteractionLabel
@onready var game_over_panel: Panel   = $GameOverPanel
@onready var game_over_reason: Label  = $GameOverPanel/VBox/Reason
@onready var victory_panel: Panel     = $VictoryPanel
@onready var countdown_label: Label   = $CountdownLabel

var _vignette_dir: float = 1.0
var _local_player: Node3D = null

func _ready() -> void:
	game_over_panel.visible = false
	victory_panel.visible   = false
	countdown_label.visible = false
	vignette.visible        = false
	interact_container.visible = false

	GameManager.game_state_changed.connect(_on_state_changed)
	GameManager.guardian_countdown_tick.connect(_on_countdown)

	if WorldProgression:
		WorldProgression.zone_changed.connect(_on_zone_changed)
		_update_zone_ui(WorldProgression.current_zone_name, WorldProgression.current_progress)

	if $GameOverPanel/VBox/RestartBtn:
		$GameOverPanel/VBox/RestartBtn.pressed.connect(
			func(): get_tree().reload_current_scene()
		)
	if $VictoryPanel/VBox/RestartBtn:
		$VictoryPanel/VBox/RestartBtn.pressed.connect(
			func(): get_tree().reload_current_scene()
		)

	await get_tree().process_frame
	_find_player()

func _process(delta: float) -> void:
	if not is_instance_valid(_local_player):
		_find_player()
		return

	var hc := _local_player.get_node_or_null("HealthComponent") as HealthComponent
	if hc:
		health_bar.max_value = hc.max_health
		health_bar.value     = hc.current_health

	var bearer := GameManager.get_torch_bearer()
	var is_bearer: bool = is_instance_valid(bearer) and bearer == _local_player
	bearer_label.visible = is_bearer

	if is_instance_valid(bearer):
		var tc := bearer.get_node_or_null("TorchComponent") as TorchComponent
		if tc:
			torch_bar.max_value = tc.max_durability
			torch_bar.value     = tc.current_durability
			_update_vignette(tc.get_ratio(), delta)

	# Update alive count
	var alive_count := 0
	for id in GameManager.all_players:
		var p = GameManager.all_players[id]
		if is_instance_valid(p):
			var phc := p.get_node_or_null("HealthComponent") as HealthComponent
			if phc and phc.is_alive():
				alive_count += 1
	alive_label.text = "Survivors: %d" % alive_count

func _on_pass_progress(ratio: float) -> void:
	if ratio > 0.0:
		interact_container.visible = true
		interact_label.text = "Transferring Torch: %d%%" % int(ratio * 100)
		interact_bar.value = ratio
	else:
		interact_container.visible = false

func _update_vignette(ratio: float, delta: float) -> void:
	if ratio < 0.3:
		vignette.visible = true
		_vignette_dir = 1.0 if vignette.color.a <= 0.0 else (-1.0 if vignette.color.a >= 0.28 else _vignette_dir)
		var new_alpha := vignette.color.a + _vignette_dir * delta * 0.9
		vignette.color = Color(0.85, 0.0, 0.0, clampf(new_alpha, 0.0, 0.28))
	else:
		vignette.visible = false

func _find_player() -> void:
	for id in GameManager.all_players:
		var p = GameManager.all_players[id]
		if is_instance_valid(p):
			_local_player = p
			if _local_player.has_signal("torch_pass_progress") and not _local_player.torch_pass_progress.is_connected(_on_pass_progress):
				_local_player.torch_pass_progress.connect(_on_pass_progress)
			break

func _on_zone_changed(_zone_id: int, zone_name: String, progress_pct: float) -> void:
	_update_zone_ui(zone_name, progress_pct)

func _update_zone_ui(zone_name: String, progress_pct: float) -> void:
	zone_label.text = "%s  |  Journey: %d%%" % [zone_name, int(progress_pct)]

func _on_state_changed(state: GameManager.GameState) -> void:
	match state:
		GameManager.GameState.GAME_OVER:
			game_over_panel.visible = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		GameManager.GameState.VICTORY:
			victory_panel.visible = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_countdown(seconds: float) -> void:
	countdown_label.visible = true
	countdown_label.text    = "GUARDIANS DOWN! %.0f s" % ceilf(seconds)
	if seconds <= 0:
		countdown_label.visible = false