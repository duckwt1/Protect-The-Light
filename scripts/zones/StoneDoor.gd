# StoneDoor.gd
# GDD §8 (Khu 4 - Thành cổ):
# Cửa đá cần giữ nút cơ cấu (E) trong 3 giây để mở.
class_name StoneDoor
extends Node3D

signal door_opened
signal interaction_progress(ratio: float)

@export var hold_time_required: float = 3.0
@export var open_height: float = 4.5

var is_open: bool = false
var _current_hold_time: float = 0.0
var _interactor: Node3D = null

@onready var door_mesh: Node3D = $DoorMesh
@onready var interaction_area: Area3D = $InteractionArea
@onready var progress_label: Label3D = $ConsoleMesh/ProgressLabel

func _ready() -> void:
	interaction_area.body_entered.connect(_on_interaction_body_entered)
	interaction_area.body_exited.connect(_on_interaction_body_exited)
	if progress_label:
		progress_label.text = "Hold [E] to Open"

func _process(delta: float) -> void:
	if is_open:
		return

	if is_instance_valid(_interactor) and Input.is_action_pressed("interact"):
		_current_hold_time += delta
		var ratio := clampf(_current_hold_time / hold_time_required, 0.0, 1.0)
		interaction_progress.emit(ratio)
		if progress_label:
			progress_label.text = "Opening: %d%%" % int(ratio * 100)

		if _current_hold_time >= hold_time_required:
			_open_door()
	else:
		if _current_hold_time > 0.0:
			_current_hold_time = maxf(0.0, _current_hold_time - delta * 2.0)
			var ratio := clampf(_current_hold_time / hold_time_required, 0.0, 1.0)
			interaction_progress.emit(ratio)
			if progress_label:
				progress_label.text = "Hold [E] to Open" if _current_hold_time == 0 else "Opening: %d%%" % int(ratio * 100)

func _open_door() -> void:
	is_open = true
	if progress_label:
		progress_label.text = "OPEN"
	door_opened.emit()
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(door_mesh, "position:y", open_height, 2.5)

func _on_interaction_body_entered(body: Node3D) -> void:
	if not is_open and (body.is_in_group("player") or body.has_method("set_as_torch_bearer")):
		_interactor = body
		if progress_label:
			progress_label.visible = true

func _on_interaction_body_exited(body: Node3D) -> void:
	if body == _interactor:
		_interactor = null
		_current_hold_time = 0.0
		if progress_label:
			progress_label.text = "Hold [E] to Open"