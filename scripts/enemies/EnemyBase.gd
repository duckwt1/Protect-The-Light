# EnemyBase.gd
# Base class for all enemies. Extend with ShadowCreeper, LightEater, etc.
# AI runs on server/offline authority only.
class_name EnemyBase
extends CharacterBody3D

enum State { IDLE, CHASE, HESITATE, ATTACK, FLEE_FROM_LIGHT }

@export var max_health: float = 25.0
@export var base_move_speed: float = 3.0
@export var damage: float = 8.0
@export var detection_range: float = 12.0
@export var attack_range: float = 1.6
@export var attack_cooldown: float = 1.2

var current_state: State = State.IDLE
var target: Node3D = null

@onready var health: HealthComponent = $HealthComponent
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var _attack_timer: float = 0.0
var _patrol_timer: float = 0.0
var _patrol_target: Vector3 = Vector3.ZERO
var _current_speed: float = 3.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	health.max_health = max_health
	health.current_health = max_health
	health.died.connect(_on_died)
	_current_speed = base_move_speed

	# Fix: run AI in offline mode too
	var is_authority: bool = (
		not multiplayer.has_multiplayer_peer() or multiplayer.is_server()
	)
	set_physics_process(is_authority)


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_update_target()

	# Determine own light zone
	var my_zone := _get_my_zone()

	match my_zone:
		0:  # DARK — aggressive
			_current_speed = base_move_speed * 1.3
			if is_instance_valid(target):
				current_state = State.CHASE
			else:
				current_state = State.IDLE
		1:  # DANGER — hesitant
			_current_speed = base_move_speed * 0.8
			if is_instance_valid(target):
				current_state = State.HESITATE
		2:  # SAFE — flee
			_current_speed = base_move_speed * 1.5
			current_state = State.FLEE_FROM_LIGHT

	_execute_state(delta)


## Returns 0=Dark, 1=Danger, 2=Safe relative to torch
func _get_my_zone() -> int:
	var bearer: Node3D = GameManager.get_torch_bearer()
	if not is_instance_valid(bearer):
		return 0
	var tc := bearer.get_node_or_null("TorchComponent") as TorchComponent
	if not tc or not tc.is_active:
		return 0
	var light := bearer.get_node_or_null("TorchLight") as OmniLight3D
	if not light:
		return 0
	var dist := global_position.distance_to(light.global_position)
	if dist > tc.danger_radius:
		return 0
	if dist <= tc.safe_radius:
		return 2
	return 1


func _update_target() -> void:
	# Check for critical torch state (GDD §6: <10% durability gives hunt buff)
	var active_detection_range := detection_range
	var bearer: Node3D = GameManager.get_torch_bearer()
	if is_instance_valid(bearer):
		var tc := bearer.get_node_or_null("TorchComponent") as TorchComponent
		if tc and tc.is_active and tc.current_durability < 10.0:
			active_detection_range = maxf(active_detection_range, 60.0) # Toàn bộ quái biết ngay vị trí
			_current_speed = _current_speed * 1.2

	# Find nearest player within detection range
	var nearest: Node3D = null
	var nearest_dist := active_detection_range
	for id in GameManager.all_players:
		var p := GameManager.all_players[id] as Node3D
		if not is_instance_valid(p):
			continue
		var hc := p.get_node_or_null("HealthComponent") as HealthComponent
		if not hc or not hc.is_alive():
			continue
		var d := global_position.distance_to(p.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = p
	target = nearest


func _execute_state(delta: float) -> void:
	match current_state:
		State.IDLE:
			_do_patrol(delta)
		State.CHASE:
			_do_move_toward_target()
			_try_attack()
		State.HESITATE:
			# Approach slowly, probe attack
			_do_move_toward_target()
			_try_attack()
		State.FLEE_FROM_LIGHT:
			_do_flee_from_light()


func _do_move_toward_target() -> void:
	if not is_instance_valid(target):
		return
	nav_agent.target_position = target.global_position
	var next_pos: Vector3
	if nav_agent.is_navigation_finished() or nav_agent.get_next_path_position() == Vector3.ZERO:
		next_pos = target.global_position
	else:
		next_pos = nav_agent.get_next_path_position()

	var dir := (next_pos - global_position)
	dir.y = 0.0
	if dir.length_squared() > 0.01:
		dir = dir.normalized()
		velocity.x = dir.x * _current_speed
		velocity.z = dir.z * _current_speed
		var target_rot := atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot, 0.2)
	else:
		velocity.x = move_toward(velocity.x, 0, _current_speed)
		velocity.z = move_toward(velocity.z, 0, _current_speed)

	move_and_slide()


func _do_patrol(delta: float) -> void:
	_patrol_timer -= delta
	if _patrol_timer <= 0.0:
		_patrol_timer = randf_range(2.0, 5.0)
		var offset := Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
		_patrol_target = global_position + offset
	nav_agent.target_position = _patrol_target
	var next_pos := nav_agent.get_next_path_position()
	var dir := (next_pos - global_position)
	dir.y = 0.0
	if dir.length_squared() > 0.01:
		dir = dir.normalized()
		velocity.x = dir.x * (base_move_speed * 0.5)
		velocity.z = dir.z * (base_move_speed * 0.5)
		var target_rot := atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot, 0.15)
	move_and_slide()


func _do_flee_from_light() -> void:
	var bearer := GameManager.get_torch_bearer()
	if not is_instance_valid(bearer):
		return
	var dir := (global_position - bearer.global_position)
	dir.y = 0.0
	if dir.length_squared() > 0.01:
		dir = dir.normalized()
		velocity.x = dir.x * _current_speed
		velocity.z = dir.z * _current_speed
		var target_rot := atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot, 0.25)
	move_and_slide()


func _try_attack() -> void:
	if _attack_timer > 0.0 or not is_instance_valid(target):
		return
	var dist := global_position.distance_to(target.global_position)
	if dist <= attack_range:
		_attack_timer = attack_cooldown
		_do_attack_hit()


func _do_attack_hit() -> void:
	if not is_instance_valid(target):
		return

	# Lunge animation effect
	var lunge_dir := (target.global_position - global_position).normalized()
	velocity += lunge_dir * 3.5

	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.15, 0.85, 1.15), 0.1)
	tween.tween_property(self, "scale", Vector3(1.0, 1.0, 1.0), 0.15)

	var hc := target.get_node_or_null("HealthComponent") as HealthComponent
	if hc:
		hc.take_damage(damage)

	# GDD §6: Bị quái thường tấn công Torch Bearer: -2 điểm độ bền đuốc
	if target == GameManager.get_torch_bearer() or ("is_torch_bearer" in target and target.is_torch_bearer):
		var tc := target.get_node_or_null("TorchComponent") as TorchComponent
		if tc and tc.is_active:
			tc.add_fuel(-2.0)


func _on_died() -> void:
	set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.3)
	await tween.finished
	queue_free()
