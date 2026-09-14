# Zone1Generator.gd
# Procedurally builds Zone 1 — Mist Forest geometry at runtime.
# Uses only primitive meshes so no external assets are needed.
extends Node3D

@export var shadow_creeper_scene: PackedScene
@export var light_eater_scene: PackedScene
@export var fuel_pickup_scene: PackedScene
@export var rest_point_scene: PackedScene

## Destination trigger — auto-found at path Destination/DestinationArea
var destination_area: Area3D


func _ready() -> void:
	_build_ground()
	_build_border_walls()
	_build_trees()
	_build_bridge()
	_place_elevations()
	_place_fuel_pickups()
	_place_rest_point()
	_bake_nav()
	# Auto-find DestinationArea from the scene tree (set by Zone1_MistForest.tscn)
	destination_area = get_node_or_null("Destination/DestinationArea") as Area3D
	call_deferred("_wire_destination")


# -----------------------------------------------------------------------
# Ground — one long corridor, 8 m wide × 70 m long
# -----------------------------------------------------------------------
func _build_ground() -> void:
	var mat := _mat(Color(0.14, 0.20, 0.10))
	_make_static_box(Vector3(0, -0.5, -35), Vector3(10, 1, 72), mat, 4)

	# Khe núi trước cầu: giảm ground xuống
	var gap_mat := _mat(Color(0.06, 0.06, 0.08))
	_make_static_box(Vector3(0, -3, -40), Vector3(10, 4, 4), gap_mat, 4)


# -----------------------------------------------------------------------
# Invisible border walls to keep the player on-path
# -----------------------------------------------------------------------
func _build_border_walls() -> void:
	var inv := _mat(Color(0, 0, 0, 0))
	inv.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Left wall
	_make_static_box(Vector3(-5.5, 1, -35), Vector3(0.5, 4, 72), inv, 4)
	# Right wall
	_make_static_box(Vector3(5.5, 1, -35), Vector3(0.5, 4, 72), inv, 4)
	# Start blocker
	_make_static_box(Vector3(0, 1, 2), Vector3(12, 4, 0.5), inv, 4)
	# End blocker
	_make_static_box(Vector3(0, 1, -73), Vector3(12, 4, 0.5), inv, 4)


# -----------------------------------------------------------------------
# Trees: cylinder trunk + stacked box canopy
# -----------------------------------------------------------------------
func _build_trees() -> void:
	var trunk_mat   := _mat(Color(0.30, 0.20, 0.12))
	var canopy_mats := [
		_mat(Color(0.10, 0.26, 0.09)),
		_mat(Color(0.12, 0.28, 0.10)),
		_mat(Color(0.08, 0.22, 0.07)),
	]
	var xs := [-6.5, 6.5]
	var z   := -2.0
	while z > -68.0:
		# Skip bridge + gap zone
		if z < -36.0 and z > -47.0:
			z -= 3.5
			continue
		for x in xs:
			var jitter := randf_range(-0.4, 0.4)
			_make_tree(Vector3(x + jitter, 0, z), trunk_mat, canopy_mats)
		z -= 3.5


func _make_tree(pos: Vector3, trunk_mat: StandardMaterial3D, canopy_mats: Array) -> void:
	var root := Node3D.new()
	add_child(root)
	root.position = pos

	# Trunk
	var trunk := MeshInstance3D.new()
	var cyl   := CylinderMesh.new()
	cyl.top_radius    = 0.18
	cyl.bottom_radius = 0.28
	cyl.height        = 3.2
	trunk.mesh = cyl
	trunk.set_surface_override_material(0, trunk_mat)
	trunk.position = Vector3(0, 1.6, 0)
	root.add_child(trunk)

	# Canopy: 3 stacked boxes
	var h_base := 3.2
	for i in 3:
		var c  := MeshInstance3D.new()
		var bm := BoxMesh.new()
		var sc := 1.0 - i * 0.22
		bm.size = Vector3(2.2 * sc, 1.1, 2.2 * sc)
		c.mesh  = bm
		c.set_surface_override_material(0, canopy_mats[i % canopy_mats.size()])
		c.position = Vector3(0, h_base + i * 1.0, 0)
		root.add_child(c)


# -----------------------------------------------------------------------
# Bridge at z=-43 (low-poly plank platform)
# -----------------------------------------------------------------------
func _build_bridge() -> void:
	var wood_mat := _mat(Color(0.42, 0.30, 0.18))
	# Main deck
	_make_static_box(Vector3(0, 0.7, -43), Vector3(3.5, 0.25, 8.0), wood_mat, 4)
	# Approach ramp
	var ramp_a := _make_static_box(Vector3(0, 0.18, -37.5), Vector3(3.5, 0.2, 3.0), wood_mat, 4)
	ramp_a.rotation_degrees.x = -14.0
	# Exit ramp
	var ramp_b := _make_static_box(Vector3(0, 0.18, -48.5), Vector3(3.5, 0.2, 3.0), wood_mat, 4)
	ramp_b.rotation_degrees.x = 14.0
	# Rope rails (visual only)
	var rail_mat := _mat(Color(0.28, 0.18, 0.08))
	_make_mesh_box(Vector3(-1.6, 1.1, -43), Vector3(0.1, 0.6, 8.0), rail_mat)
	_make_mesh_box(Vector3( 1.6, 1.1, -43), Vector3(0.1, 0.6, 8.0), rail_mat)


# -----------------------------------------------------------------------
# Small elevation for one fuel pickup
# -----------------------------------------------------------------------
func _place_elevations() -> void:
	var rock_mat := _mat(Color(0.25, 0.22, 0.18))
	_make_static_box(Vector3(-2.5, 0.35, -28), Vector3(2.5, 0.7, 2.5), rock_mat, 4)


# -----------------------------------------------------------------------
# Fuel pickups (3 positions, GDD §8)
# -----------------------------------------------------------------------
func _place_fuel_pickups() -> void:
	if not fuel_pickup_scene:
		return
	var positions := [
		Vector3(-3.5, 0.5, -12),   # Left of path, early
		Vector3( 3.5, 0.5, -24),   # Right of path, mid
		Vector3(-2.5, 1.2, -28),   # On elevated rock
	]
	for p in positions:
		var fp := fuel_pickup_scene.instantiate()
		add_child(fp)
		fp.global_position = p


# -----------------------------------------------------------------------
# Rest Point near the end of Zone 1 (GDD §8)
# -----------------------------------------------------------------------
func _place_rest_point() -> void:
	if not rest_point_scene:
		return
	var rp := rest_point_scene.instantiate()
	add_child(rp)
	rp.position = Vector3(0, 0, -58)


# -----------------------------------------------------------------------
# Wire destination trigger
# -----------------------------------------------------------------------
func _wire_destination() -> void:
	if destination_area:
		if not destination_area.body_entered.is_connected(_on_destination_reached):
			destination_area.body_entered.connect(_on_destination_reached)


func _on_destination_reached(body: Node3D) -> void:
	if body.has_method("receive_torch") or body.has_method("set_as_torch_bearer"):
		GameManager.on_reach_destination()


# -----------------------------------------------------------------------
# Bake navigation mesh at runtime
# -----------------------------------------------------------------------
func _bake_nav() -> void:
	var nav := get_node_or_null("NavigationRegion3D") as NavigationRegion3D
	if nav:
		call_deferred("_do_bake", nav)


func _do_bake(nav: NavigationRegion3D) -> void:
	nav.bake_navigation_mesh()


# -----------------------------------------------------------------------
# Helper builders
# -----------------------------------------------------------------------
func _make_static_box(pos: Vector3, size: Vector3, mat: StandardMaterial3D, layer: int) -> StaticBody3D:
	var sb  := StaticBody3D.new()
	sb.collision_layer = layer
	sb.collision_mask  = 0
	add_child(sb)
	sb.position = pos

	var mi  := MeshInstance3D.new()
	var bm  := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.set_surface_override_material(0, mat)
	sb.add_child(mi)

	var cs    := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape   = shape
	sb.add_child(cs)
	return sb


func _make_mesh_box(pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	add_child(mi)
	return mi


func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness    = 0.95
	return m
