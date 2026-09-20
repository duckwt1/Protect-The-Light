# MudArea.gd
# GDD §8 (Khu 2 - Đầm lầy): Giảm tốc độ toàn đội -25% khi đi trong bùn
class_name MudArea
extends Area3D

@export var speed_reduction_factor: float = 0.75  # Tốc độ còn 75% (-25%)

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1  # Player layer
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("set_mud_slowdown"):
		body.set_mud_slowdown(speed_reduction_factor)

func _on_body_exited(body: Node3D) -> void:
	if body.has_method("set_mud_slowdown"):
		body.set_mud_slowdown(1.0)