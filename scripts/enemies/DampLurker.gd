# DampLurker.gd
# GDD §9: HP=35, Tốc độ 2.7 m/s (lao vồ 5.3 m/s trong 1s), Sát thương 12
# Ẩn mình dưới đầm lầy, phục kích người chơi khi tới gần nước.
class_name DampLurker
extends EnemyBase

enum LurkState { SUBMERGED, LEAPING, RECOVERING }
var lurk_state: LurkState = LurkState.SUBMERGED

@export var ambush_range: float = 4.0
@export var leap_speed: float = 5.3
@export var ambush_delay: float = 1.0

var _ambush_timer: float = 0.0
var _leap_timer: float = 0.0
var _original_y: float = 0.0

@onready var visual_mesh: Node3D = $VisualModel if has_node("VisualModel") else $MeshInstance3D

func _ready() -> void:
	max_health = 35.0
	base_move_speed = 2.7
	damage = 12.0
	detection_range = 10.0
	attack_range = 1.8
	attack_cooldown = 1.6
	super._ready()
	_original_y = visual_mesh.position.y
	_submerge()

func _submerge() -> void:
	lurk_state = LurkState.SUBMERGED
	# Thu nhỏ mesh và chìm xuống bùn
	visual_mesh.scale = Vector3(0.9, 0.2, 0.9)
	visual_mesh.position.y = _original_y - 0.6

func _surface() -> void:
	lurk_state = LurkState.LEAPING
	_leap_timer = 1.0
	visual_mesh.scale = Vector3(1.0, 1.0, 1.0)
	visual_mesh.position.y = _original_y

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() and multiplayer.has_multiplayer_peer():
		return

	match lurk_state:
		LurkState.SUBMERGED:
			_update_target()
			if is_instance_valid(target):
				var dist := global_position.distance_to(target.global_position)
				if dist <= ambush_range:
					_ambush_timer += delta
					if _ambush_timer >= ambush_delay:
						_surface()
				else:
					_ambush_timer = 0.0
		LurkState.LEAPING:
			_leap_timer -= delta
			if is_instance_valid(target):
				var dir := (target.global_position - global_position)
				dir.y = 0.0
				dir = dir.normalized()
				velocity.x = dir.x * leap_speed
				velocity.z = dir.z * leap_speed
				if dir.length_squared() > 0.01:
					look_at(global_position + dir, Vector3.UP)
				move_and_slide()
				_try_attack()

			if _leap_timer <= 0.0:
				lurk_state = LurkState.RECOVERING
		LurkState.RECOVERING:
			# Sau khi vồ xong, chuyển sang hành vi EnemyBase bình thường
			super._physics_process(delta)