# EnemySpawner.gd
# Spawns waves of enemies for Zone 1 (GDD §8: max 3 enemies at once in Zone 1).
extends Node3D

@export var shadow_creeper_scene: PackedScene
@export var light_eater_scene: PackedScene
@export var spawn_points: Array[NodePath] = []
@export var max_enemies_zone1: int = 3
@export var spawn_interval: float = 8.0   # seconds between spawns

var _enemies_alive: int = 0
var _spawn_timer: float = 5.0   # initial delay
var _light_eater_timer: float = 45.0  # first light eater after 45s


func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = spawn_interval
		_try_spawn_creeper()

	_light_eater_timer -= delta
	if _light_eater_timer <= 0.0:
		_light_eater_timer = 60.0
		_try_spawn_light_eater()


func _try_spawn_creeper() -> void:
	if _enemies_alive >= max_enemies_zone1:
		return
	if not shadow_creeper_scene:
		return
	var pt := _get_random_spawn_point()
	if pt == Vector3.ZERO:
		return
	var enemy := shadow_creeper_scene.instantiate()
	get_parent().add_child(enemy)
	enemy.global_position = pt
	_enemies_alive += 1
	# Track death
	var hc := enemy.get_node_or_null("HealthComponent") as HealthComponent
	if hc:
		hc.died.connect(func(): _enemies_alive = maxi(_enemies_alive - 1, 0))


func _try_spawn_light_eater() -> void:
	if not light_eater_scene:
		return
	var bearer := GameManager.get_torch_bearer()
	if not is_instance_valid(bearer):
		return
	var le := light_eater_scene.instantiate()
	get_parent().add_child(le)
	# Spawn above the bearer
	le.global_position = bearer.global_position + Vector3(randf_range(-3, 3), 3, randf_range(-3, 3))


func _get_random_spawn_point() -> Vector3:
	if spawn_points.is_empty():
		# Fallback: spawn near bearer but outside safe zone
		var bearer := GameManager.get_torch_bearer()
		if not is_instance_valid(bearer):
			return Vector3.ZERO
		var angle := randf() * TAU
		var dist  := randf_range(8, 15)
		return bearer.global_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)

	var path := spawn_points[randi() % spawn_points.size()]
	var node := get_node_or_null(path) as Node3D
	return node.global_position if node else Vector3.ZERO
