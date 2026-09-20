# ShadowCreeperExtinguisher.gd
# GDD §9: Shadow Creeper "Dập Tắt" (Khu 4)
# HP=40, Tốc độ 2.9 m/s, Sát thương 8.
# Ưu tiên bám theo Torch Bearer. Áp sát >3s gây thêm -7 độ bền/giây.
class_name ShadowCreeperExtinguisher
extends EnemyBase

const EXTINGUISH_DRAIN_RATE := 7.0  # -7 độ bền / giây
const PROXIMITY_THRESHOLD := 2.5   # Bán kính áp sát 2.5m
const STILL_TIME_TRIGGER := 3.0   # Cần áp sát > 3s

var _close_timer: float = 0.0
var is_extinguishing: bool = false

@onready var aura_light: OmniLight3D = $AuraLight

func _ready() -> void:
	max_health = 40.0
	base_move_speed = 2.9
	damage = 8.0
	detection_range = 16.0
	attack_range = 1.7
	attack_cooldown = 1.1
	super._ready()

func _update_target() -> void:
	# Luôn ưu tiên mục tiêu là Torch Bearer
	var bearer := GameManager.get_torch_bearer()
	if is_instance_valid(bearer):
		var hc := bearer.get_node_or_null("HealthComponent") as HealthComponent
		if hc and hc.is_alive():
			target = bearer
			return
	super._update_target()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	var bearer := GameManager.get_torch_bearer()
	if is_instance_valid(bearer):
		var dist := global_position.distance_to(bearer.global_position)
		if dist <= PROXIMITY_THRESHOLD:
			_close_timer += delta
			if _close_timer >= STILL_TIME_TRIGGER:
				is_extinguishing = true
				if aura_light:
					aura_light.visible = true
				var tc := bearer.get_node_or_null("TorchComponent") as TorchComponent
				if tc and tc.is_active:
					tc.add_fuel(-EXTINGUISH_DRAIN_RATE * delta)
		else:
			_close_timer = maxf(0.0, _close_timer - delta * 1.5)
			if _close_timer < STILL_TIME_TRIGGER:
				is_extinguishing = false
				if aura_light:
					aura_light.visible = false
	else:
		is_extinguishing = false
		if aura_light:
			aura_light.visible = false