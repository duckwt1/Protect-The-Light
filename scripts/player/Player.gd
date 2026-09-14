# Player.gd
# CharacterBody3D root script.
# Handles: movement, over-the-shoulder camera, torch-bearer/guardian roles,
# zone damage (GDD §5), attack (LMB), torch-pass (hold E).
extends CharacterBody3D

# --- Speed constants (GDD §4) ---
const SPEED_BEARER   := 2.7   # m/s
const SPEED_GUARDIAN := 3.3   # m/s

# --- Zone damage (GDD §5) ---
const DANGER_GRACE_TIME   := 5.0   # s before Danger starts hurting
const DANGER_DAMAGE_RATE  := 2.0   # HP / 2 s
const DARK_DAMAGE_RATE    := 8.0   # HP / 2 s

# --- Melee / knockback ---
const ATTACK_COOLDOWN     := 0.8
const ATTACK_DAMAGE_MIN   := 15.0
const ATTACK_DAMAGE_MAX   := 25.0
const ATTACK_KNOCKBACK    := 7.0
const BEARER_KNOCKBACK    := 5.0
const ATTACK_REACH        := 2.5   # metres (raycast length)

# --- Torch pass (GDD §4) ---
const PASS_HOLD_TIME      := 1.2   # s
const PASS_RADIUS         := 1.5   # m

@onready var health: HealthComponent    = $HealthComponent
@onready var torch: TorchComponent      = $TorchComponent
@onready var camera_pivot: Node3D       = $CameraPivot
@onready var spring_arm: SpringArm3D    = $CameraPivot/SpringArm3D
@onready var camera: Camera3D           = $CameraPivot/SpringArm3D/Camera3D
@onready var interaction_area: Area3D   = $InteractionArea
@onready var torch_light: OmniLight3D   = $TorchLight

var is_torch_bearer: bool = false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var mouse_sensitivity: float = 0.003

# Zone state
enum ZoneType { DARK, DANGER, SAFE }
var current_zone: ZoneType = ZoneType.DARK
var _danger_timer: float  = 0.0
var _dmg_tick_timer: float = 0.0

# Attack
var _attack_cd: float = 0.0

# Torch pass
var _pass_timer: float  = 0.0
var _pass_target: Node3D = null
var _passing: bool = false

# Camera
var _cam_spring_default: float = 4.0


func _ready() -> void:
	_cam_spring_default = spring_arm.spring_length
	var local: bool = not multiplayer.has_multiplayer_peer() or is_multiplayer_authority()
	camera.current = local
	if local:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if health:
		health.died.connect(_on_died)

	# Register with GameManager
	var peer_id: int = multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 1
	GameManager.register_player(peer_id, self)

	# Demo: first (only) player starts as Torch Bearer
	set_as_torch_bearer(true)


func _unhandled_input(event: InputEvent) -> void:
	if not _is_local():
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		camera_pivot.rotation.x = clamp(
			camera_pivot.rotation.x, deg_to_rad(-60), deg_to_rad(40)
		)

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = (
			Input.MOUSE_MODE_VISIBLE
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)

	if event.is_action_pressed("attack") and _attack_cd <= 0.0:
		_do_attack()

	if event.is_action_pressed("interact") and is_torch_bearer:
		_begin_pass()
	if event.is_action_released("interact"):
		_cancel_pass()


func _physics_process(delta: float) -> void:
	if not _is_local():
		return

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# WASD movement
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction  := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var speed      := SPEED_BEARER if is_torch_bearer else SPEED_GUARDIAN

	if direction.length_squared() > 0.0:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

	# Timers
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	_update_zone_damage(delta)
	_update_pass(delta)


# ---------------------------------------------------------------------------
# Zone detection & damage (GDD §5)
# ---------------------------------------------------------------------------
func _update_zone_damage(delta: float) -> void:
	current_zone = _calc_zone()
	match current_zone:
		ZoneType.SAFE:
			_danger_timer    = 0.0
			_dmg_tick_timer  = 0.0
		ZoneType.DANGER:
			_danger_timer += delta
			if _danger_timer >= DANGER_GRACE_TIME:
				_dmg_tick_timer += delta
				if _dmg_tick_timer >= 2.0:
					_dmg_tick_timer = 0.0
					health.take_damage(DANGER_DAMAGE_RATE)
		ZoneType.DARK:
			_danger_timer = 0.0
			_dmg_tick_timer += delta
			if _dmg_tick_timer >= 2.0:
				_dmg_tick_timer = 0.0
				health.take_damage(DARK_DAMAGE_RATE)


func _calc_zone() -> ZoneType:
	var bearer: Node3D = GameManager.get_torch_bearer()
	if not is_instance_valid(bearer):
		return ZoneType.DARK
	if bearer == self:
		return ZoneType.SAFE   # bearer is always safe

	var tc := bearer.get_node_or_null("TorchComponent") as TorchComponent
	if not tc or not tc.is_active:
		return ZoneType.DARK

	var light := bearer.get_node_or_null("TorchLight") as OmniLight3D
	if not light:
		return ZoneType.DARK

	var dist := global_position.distance_to(light.global_position)
	if dist > tc.danger_radius:
		return ZoneType.DARK
	if _light_occluded(light.global_position):
		return ZoneType.DARK
	if dist <= tc.safe_radius:
		return ZoneType.SAFE
	return ZoneType.DANGER


func _light_occluded(light_pos: Vector3) -> bool:
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		light_pos, global_position + Vector3.UP * 0.8
	)
	q.exclude  = [get_rid()]
	q.collision_mask = 4   # World layer
	return not space.intersect_ray(q).is_empty()


# ---------------------------------------------------------------------------
# Attack
# ---------------------------------------------------------------------------
func _do_attack() -> void:
	_attack_cd = ATTACK_COOLDOWN
	var space := get_world_3d().direct_space_state
	var origin := camera.global_position
	var dir    := -camera.global_transform.basis.z
	var q := PhysicsRayQueryParameters3D.create(origin, origin + dir * ATTACK_REACH)
	q.exclude        = [get_rid()]
	q.collision_mask = 2   # Enemy layer
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return
	var body := hit["collider"] as Node3D
	if not body:
		return

	var away_dir := (body.global_position - global_position).normalized()
	if is_torch_bearer:
		# Knockback only (GDD §4)
		if body is CharacterBody3D:
			body.velocity += away_dir * BEARER_KNOCKBACK
	else:
		var hc := body.get_node_or_null("HealthComponent") as HealthComponent
		if hc:
			hc.take_damage(randf_range(ATTACK_DAMAGE_MIN, ATTACK_DAMAGE_MAX))
		if body is CharacterBody3D:
			body.velocity += away_dir * ATTACK_KNOCKBACK


# ---------------------------------------------------------------------------
# Torch pass (GDD §4: hold E 1.2 s within 1.5 m)
# ---------------------------------------------------------------------------
func _begin_pass() -> void:
	for body in interaction_area.get_overlapping_bodies():
		if body != self and body.has_method("receive_torch"):
			_pass_target = body
			_pass_timer  = 0.0
			_passing     = true
			return


func _cancel_pass() -> void:
	_pass_target = null
	_pass_timer  = 0.0
	_passing     = false


func _update_pass(delta: float) -> void:
	if not _passing or not is_torch_bearer:
		return
	if not is_instance_valid(_pass_target) or not Input.is_action_pressed("interact"):
		_cancel_pass()
		return
	if global_position.distance_to(_pass_target.global_position) > PASS_RADIUS:
		_cancel_pass()
		return
	_pass_timer += delta
	if _pass_timer >= PASS_HOLD_TIME:
		_complete_pass()


func _complete_pass() -> void:
	if not _pass_target or not is_instance_valid(_pass_target):
		return
	_pass_target.receive_torch()
	set_as_torch_bearer(false)
	GameManager.set_torch_bearer(_pass_target)
	_cancel_pass()


func receive_torch() -> void:
	set_as_torch_bearer(true)


# ---------------------------------------------------------------------------
# Role management
# ---------------------------------------------------------------------------
func set_as_torch_bearer(active: bool) -> void:
	is_torch_bearer = active
	if torch:
		torch.set_active(active)
	if torch_light:
		torch_light.visible = active
	if active:
		health.max_health = 80.0
	else:
		health.max_health = 100.0


func take_damage(amount: float) -> void:
	if health:
		health.take_damage(amount)


func _on_died() -> void:
	set_physics_process(false)
	set_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if is_torch_bearer:
		GameManager.on_torch_bearer_died()
	else:
		GameManager.on_guardian_died()


func _is_local() -> bool:
	return not multiplayer.has_multiplayer_peer() or is_multiplayer_authority()
