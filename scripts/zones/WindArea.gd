# WindArea.gd
# GDD §6 & §8 (Khu 3 - Rừng già & Gió mạnh):
# Đứng yên >3 giây trong vùng gió mạnh làm hao đuốc -1.2 điểm/giây
class_name WindArea
extends Area3D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1  # Player layer
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.has_node("TorchComponent"):
		var tc := body.get_node("TorchComponent") as TorchComponent
		if tc:
			tc.is_in_wind_zone = true

func _on_body_exited(body: Node3D) -> void:
	if body.has_node("TorchComponent"):
		var tc := body.get_node("TorchComponent") as TorchComponent
		if tc:
			tc.is_in_wind_zone = false