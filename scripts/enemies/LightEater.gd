# LightEater.gd
# GDD §9: HP=20, speed=2.4 m/s, dmg=5 HP + -10 torch durability.
# Flies straight at OmniLight3D — ignores NavMesh.
extends CharacterBody3D

@export var max_health: float = 20.0
@export var move_speed: float = 2.4
@export var dmg_to_player: float = 5.0
@export var dmg_to_torch: float = 10.0

@onready var health: HealthComponent = $HealthComponent

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _hit_cooldown: float = 0.0


func _ready() -> void:
	health.max_health   = max_health
	health.current_health = max_health
	health.died.connect(_on_died)
	var is_authority: bool = (
		not multiplayer.has_multiplayer_peer() or multiplayer.is_server()
	)
	set_physics_process(is_authority)


func _physics_process(delta: float) -> void:
	_hit_cooldown = maxf(_hit_cooldown - delta, 0.0)

	# Fly toward torch light position
	var bearer: Node3D = GameManager.get_torch_bearer()
	if not is_instance_valid(bearer):
		return
	var tc := bearer.get_node_or_null("TorchComponent") as TorchComponent
	if not tc or not tc.is_active:
		return
	var light := bearer.get_node_or_null("TorchLight") as OmniLight3D
	if not light:
		return

	var target_pos := light.global_position
	var dir := (target_pos - global_position).normalized()
	velocity = dir * move_speed
	move_and_slide()

	# Check collision / proximity to torch
	var dist := global_position.distance_to(target_pos)
	if dist < 0.8 and _hit_cooldown <= 0.0:
		_hit_cooldown = 1.5
		tc.add_fuel(-dmg_to_torch)  # add negative = drain
		var hc := bearer.get_node_or_null("HealthComponent") as HealthComponent
		if hc:
			hc.take_damage(dmg_to_player)


func _on_died() -> void:
	set_physics_process(false)
	queue_free()
