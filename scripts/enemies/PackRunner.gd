# PackRunner.gd
# GDD §9: HP=18/con, Tốc độ 3.6 m/s, Sát thương 6/đòn
# Di chuyển theo formation bầy 3 con, bọc lót bao vây (flanking).
class_name PackRunner
extends EnemyBase

@export var pack_offset_angle: float = 0.0  # -45°, 0°, +45° tùy vị trí trong bầy

func _ready() -> void:
	max_health = 18.0
	base_move_speed = 3.6
	damage = 6.0
	detection_range = 14.0
	attack_range = 1.5
	attack_cooldown = 0.9
	super._ready()

func _do_move_toward_target() -> void:
	if not is_instance_valid(target):
		return

	# Tính toán vị trí bao vây bọc sườn (Flanking offset)
	var target_pos := target.global_position
	if absf(pack_offset_angle) > 0.01:
		var dir_to_target := (target_pos - global_position).normalized()
		var rotated_offset := dir_to_target.rotated(Vector3.UP, deg_to_rad(pack_offset_angle)) * 2.5
		nav_agent.target_position = target_pos + rotated_offset
	else:
		nav_agent.target_position = target_pos

	var next_pos := nav_agent.get_next_path_position()
	if nav_agent.is_navigation_finished() or next_pos == Vector3.ZERO:
		next_pos = target_pos

	var dir := (next_pos - global_position)
	dir.y = 0.0
	dir = dir.normalized()
	velocity.x = dir.x * _current_speed
	velocity.z = dir.z * _current_speed
	if dir.length_squared() > 0.01:
		look_at(global_position + dir, Vector3.UP)
	move_and_slide()