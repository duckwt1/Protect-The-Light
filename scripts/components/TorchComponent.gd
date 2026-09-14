# TorchComponent.gd
# Manages torch durability, OmniLight3D scaling, and derived zone radii.
# Server/offline authority drives drain; clients read values for rendering.
class_name TorchComponent
extends Node

signal durability_changed(current: float, max_durability: float)
signal torch_extinguished
signal warning_low      ## Fired once when durability drops below 30
signal warning_critical ## Fired once when durability drops below 10

@export var max_durability: float = 100.0
@export var natural_drain_per_second: float = 0.35   # GDD §6: 0.35/s
@export var wind_drain_per_second: float = 1.2       # GDD §6: +1.2/s when stationary >3s in wind zone

## Public state read by enemies and Player zone detection
var current_durability: float = 100.0
var is_active: bool = false
var is_in_wind_zone: bool = false

## Derived radii (GDD §5), updated each frame
var safe_radius: float = 1.8
var danger_radius: float = 3.3

const SAFE_RADIUS_FULL   := 1.8
const DANGER_RADIUS_FULL := 3.3

var _wind_still_timer: float = 0.0
var _low_fired: bool = false
var _critical_fired: bool = false

@onready var light: OmniLight3D = get_parent().get_node_or_null("TorchLight")


func _ready() -> void:
	current_durability = max_durability
	set_active(false)


func _process(delta: float) -> void:
	if not is_active:
		return
	# Offline or server is authoritative
	var is_authority: bool = (
		not multiplayer.has_multiplayer_peer() or multiplayer.is_server()
	)
	if not is_authority:
		_update_light()   # clients still render correctly
		return

	# --- Drain ---
	var drain: float = natural_drain_per_second
	if is_in_wind_zone:
		var body := get_parent() as CharacterBody3D
		if body and body.velocity.length_squared() < 0.01:
			_wind_still_timer += delta
		else:
			_wind_still_timer = 0.0
		if _wind_still_timer >= 3.0:
			drain += wind_drain_per_second

	current_durability = maxf(current_durability - drain * delta, 0.0)
	_update_light()
	durability_changed.emit(current_durability, max_durability)

	# Threshold signals (fire once per crossing)
	if current_durability < 30.0 and not _low_fired:
		_low_fired = true
		warning_low.emit()
	if current_durability < 10.0 and not _critical_fired:
		_critical_fired = true
		warning_critical.emit()

	if current_durability <= 0.0:
		is_active = false
		if light:
			light.visible = false
		torch_extinguished.emit()
		if GameManager:
			GameManager.on_torch_extinguished()


func set_active(active: bool) -> void:
	is_active = active
	_low_fired = current_durability < 30.0
	_critical_fired = current_durability < 10.0
	_update_light()


## +25 per fuel pickup (GDD §6)
func add_fuel(amount: float) -> void:
	current_durability = minf(current_durability + amount, max_durability)
	_low_fired = current_durability < 30.0
	_critical_fired = current_durability < 10.0
	_update_light()
	durability_changed.emit(current_durability, max_durability)


## 0.0 – 1.0 ratio used by enemies and Player
func get_ratio() -> float:
	return current_durability / max_durability


func _update_light() -> void:
	var ratio := get_ratio()
	safe_radius   = SAFE_RADIUS_FULL   * ratio
	danger_radius = DANGER_RADIUS_FULL * ratio

	if not light:
		return
	if not is_active:
		light.visible = false
		return
	light.visible = true
	# Light range slightly wider than danger_radius for visual overlap
	light.omni_range   = lerpf(1.5, 9.0, ratio)
	light.light_energy = lerpf(0.2, 3.2, ratio)
