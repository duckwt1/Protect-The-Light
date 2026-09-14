# RestPoint.gd
# GDD §6: Full torch recharge at the one rest point in the game.
# Also heals all players to full HP.
extends Node3D

var _used: bool = false

@onready var area: Area3D = $Area3D
@onready var light: OmniLight3D = $OmniLight3D


func _ready() -> void:
	area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _used:
		return
	if not body.has_method("receive_torch"):
		return  # Not a player
	_used = true

	# Heal all players and restore torch
	for id in GameManager.all_players:
		var p := GameManager.all_players[id] as Node3D
		if not is_instance_valid(p):
			continue
		var hc := p.get_node_or_null("HealthComponent") as HealthComponent
		if hc:
			hc.heal(hc.max_health)

	var bearer := GameManager.get_torch_bearer()
	if is_instance_valid(bearer):
		var tc := bearer.get_node_or_null("TorchComponent") as TorchComponent
		if tc:
			tc.add_fuel(tc.max_durability)

	# Visual feedback: light pulses brighter
	if light:
		var tween := create_tween()
		tween.tween_property(light, "light_energy", 8.0, 0.3)
		tween.tween_property(light, "light_energy", 3.0, 1.0)

	print("Rest Point used — torch and HP restored!")
