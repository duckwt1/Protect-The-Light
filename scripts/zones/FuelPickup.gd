# FuelPickup.gd
# GDD §6: +25 torch durability on pickup. Any player can pick it up.
extends Area3D

@export var fuel_amount: float = 25.0

var _collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _collected:
		return
	if not body.has_method("set_as_torch_bearer"):
		return  # Not a player

	_collected = true

	# Always give fuel to the active Torch Bearer
	var bearer: Node3D = GameManager.get_torch_bearer()
	if is_instance_valid(bearer):
		var tc := bearer.get_node_or_null("TorchComponent") as TorchComponent
		if tc:
			tc.add_fuel(fuel_amount)

	# Animate disappear
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.25)
	tween.tween_callback(queue_free)
