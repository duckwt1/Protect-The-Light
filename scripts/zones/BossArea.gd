# BossArea.gd
# GDD §8 (Boss Area / Đích đến):
# Đấu trường tròn mở, vòng tròn ánh sáng cứu rỗi vĩ đại.
# Đợt quái dồn dập bao vây từ mọi hướng.
# Torch Bearer chạm vào vòng sáng đích -> CHIẾN THẮNG!
class_name BossArea
extends Node3D

@export var shadow_creeper_scene: PackedScene
@export var pack_runner_scene: PackedScene

@onready var victory_area: Area3D = $FinalLightSanctuary/VictoryArea
@onready var zone_trigger: Area3D = $ZoneTrigger

var _horde_active: bool = false
var _spawn_timer: float = 0.0

func _ready() -> void:
	victory_area.body_entered.connect(_on_victory_body_entered)
	zone_trigger.body_entered.connect(_on_zone_entered)

func _on_zone_entered(body: Node3D) -> void:
	if not _horde_active and (body.has_method("set_as_torch_bearer") or body.is_in_group("player")):
		_horde_active = true
		WorldProgression.set_zone(WorldProgression.ZoneID.BOSS_AREA)
		print("BOSS AREA REACHED! Final horde approaching!")

func _process(delta: float) -> void:
	if not _horde_active or GameManager.current_state != GameManager.GameState.PLAYING:
		return

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = 4.0  # Spawn wave mỗi 4s
		_spawn_horde_enemy()

func _spawn_horde_enemy() -> void:
	var bearer := GameManager.get_torch_bearer()
	if not is_instance_valid(bearer):
		return

	var angle := randf() * TAU
	var dist := randf_range(16.0, 22.0)
	var spawn_pos := bearer.global_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)

	var scene_to_spawn := shadow_creeper_scene if randf() > 0.4 else pack_runner_scene
	if scene_to_spawn:
		var enemy = scene_to_spawn.instantiate()
		add_child(enemy)
		enemy.global_position = spawn_pos

func _on_victory_body_entered(body: Node3D) -> void:
	# Kiểm tra người chạm vòng sáng có phải là Torch Bearer hay không (GDD §12)
	var is_bearer: bool = false
	if "is_torch_bearer" in body and body.is_torch_bearer:
		is_bearer = true
	elif body == GameManager.get_torch_bearer():
		is_bearer = true

	if is_bearer:
		print("VICTORY! Torch Bearer has reached the Final Light Circle!")
		WorldProgression.trigger_victory()