# ZoneTrigger.gd
# Helper Area3D script to trigger zone transition in WorldProgression
class_name ZoneTrigger
extends Area3D

@export var target_zone_id: WorldProgression.ZoneID = WorldProgression.ZoneID.ZONE_2_SWAMP

var _triggered: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1  # Player layer
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not _triggered and (body.is_in_group("player") or body.has_method("set_as_torch_bearer")):
		_triggered = true
		if WorldProgression:
			WorldProgression.set_zone(target_zone_id)