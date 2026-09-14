# ShadowCreeper.gd
# GDD §9: HP=25, speed=3.0 m/s, dmg=8/hit
# Extends EnemyBase — overrides just the state behaviours.
extends EnemyBase


func _ready() -> void:
	max_health    = 25.0
	base_move_speed = 3.0
	damage        = 8.0
	detection_range = 12.0
	attack_range  = 1.6
	attack_cooldown = 1.2
	super._ready()
