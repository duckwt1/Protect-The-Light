# WorldProgression.gd
# Autoload — Quản lý chuyển zone và tính % tiến trình hành trình (GDD §10, §11)
extends Node

enum ZoneID {
	ZONE_1_MIST_FOREST = 1,
	REST_POINT = 2,
	ZONE_2_SWAMP = 3,
	ZONE_3_WIND_FOREST = 4,
	ZONE_4_RUINED_CASTLE = 5,
	BOSS_AREA = 6
}

signal zone_changed(zone_id: ZoneID, zone_name: String, progress_pct: float)
signal game_victory

var current_zone: ZoneID = ZoneID.ZONE_1_MIST_FOREST
var current_zone_name: String = "Zone 1: Mist Forest"
var current_progress: float = 0.0

const ZONE_DATA := {
	ZoneID.ZONE_1_MIST_FOREST: {"name": "Zone 1: Mist Forest", "pct": 10.0},
	ZoneID.REST_POINT: {"name": "Sanctuary: Rest Point", "pct": 25.0},
	ZoneID.ZONE_2_SWAMP: {"name": "Zone 2: Gloomy Swamp", "pct": 45.0},
	ZoneID.ZONE_3_WIND_FOREST: {"name": "Zone 3: Ancient Windwood", "pct": 70.0},
	ZoneID.ZONE_4_RUINED_CASTLE: {"name": "Zone 4: Ruined Castle", "pct": 90.0},
	ZoneID.BOSS_AREA: {"name": "The Final Light", "pct": 100.0}
}

func _ready() -> void:
	print("WorldProgression initialized at Zone 1")

func set_zone(new_zone: ZoneID) -> void:
	current_zone = new_zone
	if ZONE_DATA.has(new_zone):
		current_zone_name = ZONE_DATA[new_zone]["name"]
		current_progress = ZONE_DATA[new_zone]["pct"]
	zone_changed.emit(current_zone, current_zone_name, current_progress)
	print("Entered %s (Progress: %d%%)" % [current_zone_name, int(current_progress)])

	if new_zone == ZoneID.BOSS_AREA:
		# Bắt đầu đếm ngược hoặc chuẩn bị sự kiện cao trào
		pass

func trigger_victory() -> void:
	if GameManager:
		GameManager.on_reach_destination()
	game_victory.emit()