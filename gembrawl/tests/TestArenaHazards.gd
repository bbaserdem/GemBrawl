## Test scene for arena hazards and spawn points
## Tests the hexagonal arena with environmental hazards (lava/spikes) and spawn points
extends Node3D

## This test scene tests hazards with the actual game systems to ensure integration works correctly

@onready var camera: Camera3D = $Camera3D
@onready var test_player = $TestPlayer  # This is now a Player3D instance
@onready var health_label: Label = $UI/HealthLabel
@onready var hazard_label: Label = $UI/HazardLabel
@onready var arena_root: Node3D = $ArenaRoot

# Camera settings - fixed isometric view
var camera_distance: float = 20.0
var camera_height: float = 25.0
var camera_angle: float = -60.0  # degrees

# Hazard tracking
var hazards_touching: Array = []
var last_damage_time: float = 0.0
var damage_interval: float = 1.0

# Arena data
var spawn_points: Array = []
var floor_tiles: Dictionary = {}
var hazard_data: Dictionary = {}  # hex_coord -> hazard_type

# Arena configuration
@export var arena_radius: int = 8
@export var hazard_count: int = 15

func _ready() -> void:
	# Set camera to fixed isometric view
	camera.position = Vector3(0, camera_height, camera_distance)
	camera.rotation_degrees = Vector3(camera_angle, 0, 0)
	
	# Always use simple arena for testing
	create_simple_arena()
	
	# Initialize the Player3D instance
	if test_player:
		# Set player properties
		test_player.player_id = 1
		test_player.is_local_player = true
		
		# Connect to player's health changed signal if available
		if test_player.stats and test_player.stats.has_signal("health_changed"):
			test_player.stats.health_changed.connect(_on_player_health_changed)
		
		# Initialize the player with the arena (even though we're not using HexArena)
		test_player.setup(null)
		
		# Place player at first spawn point
		if spawn_points.size() > 0:
			test_player.position = spawn_points[0]
			test_player.position.y = 2.0
	
	update_health_display()

func create_simple_arena() -> void:
	# Create ground collision
	create_ground_collision()
	
	# Generate hex-style floor
	generate_hex_floor()
	
	# Create hazard zones
	generate_hazards()
	
	# Create spawn points
	generate_spawn_points()

func create_ground_collision() -> void:
	var ground = StaticBody3D.new()
	var ground_shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	ground_shape.shape = box
	ground.add_child(ground_shape)
	ground.position.y = -0.5
	arena_root.add_child(ground)
	
	# Visual ground plane
	var ground_mesh = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(40, 40)
	ground_mesh.mesh = plane
	var ground_mat = StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.2, 0.2, 0.2)
	ground_mesh.material_override = ground_mat
	ground_mesh.position.y = 0.01
	arena_root.add_child(ground_mesh)

func generate_hex_floor() -> void:
	# Create hexagonal floor pattern
	for q in range(-arena_radius, arena_radius + 1):
		var r1 = max(-arena_radius, -q - arena_radius)
		var r2 = min(arena_radius, -q + arena_radius)
		
		for r in range(r1, r2 + 1):
			var hex_coord = Vector2i(q, r)
			create_floor_tile(hex_coord)

func generate_hazards() -> void:
	var spike_count = int(hazard_count * 0.3)
	var placed = 0
	var attempts = 0
	
	while placed < hazard_count and attempts < hazard_count * 10:
		attempts += 1
		var q = randi_range(-arena_radius + 2, arena_radius - 2)
		var r = randi_range(-arena_radius + 2, arena_radius - 2)
		
		if abs(q + r) <= arena_radius - 2:
			var hex_coord = Vector2i(q, r)
			if not hazard_data.has(hex_coord):
				var is_spike = placed < spike_count
				create_hazard_tile(hex_coord, is_spike)
				hazard_data[hex_coord] = "spike" if is_spike else "lava"
				placed += 1

func generate_spawn_points() -> void:
	var colors = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW]
	var angle_step = TAU / 4
	var spawn_radius = arena_radius * 0.7
	
	for i in range(4):
		var angle = i * angle_step
		var x = spawn_radius * cos(angle)
		var z = spawn_radius * sin(angle)
		var hex_coord = world_to_hex(Vector3(x, 0, z))
		
		# Ensure spawn is safe
		if not hazard_data.has(hex_coord):
			var pos = hex_to_world(hex_coord)
			create_spawn_visual(pos, colors[i])
			spawn_points.append(pos)

func create_floor_tile(hex_coord: Vector2i) -> void:
	var mesh = MeshInstance3D.new()
	mesh.mesh = create_hex_mesh()
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.6, 0.6)
	mesh.material_override = mat
	mesh.position = hex_to_world(hex_coord)
	mesh.position.y = 0.1
	arena_root.add_child(mesh)
	floor_tiles[hex_coord] = mesh

func create_hazard_tile(hex_coord: Vector2i, is_spike: bool) -> void:
	# Visual hazard
	var mesh = MeshInstance3D.new()
	mesh.mesh = create_hex_mesh()
	var mat = StandardMaterial3D.new()
	
	if is_spike:
		mat.albedo_color = Color(0.3, 0.3, 0.4)
		mat.metallic = 0.5
		# Add spike visual
		var spike_mesh = MeshInstance3D.new()
		var cone = CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.3
		cone.height = 0.8
		spike_mesh.mesh = cone
		spike_mesh.position.y = 0.4
		mesh.add_child(spike_mesh)
	else:
		mat.albedo_color = Color(1.0, 0.3, 0.0)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.5, 0.0)
		mat.emission_energy = 0.5
	
	mesh.material_override = mat
	mesh.position = hex_to_world(hex_coord)
	mesh.position.y = 0.2
	arena_root.add_child(mesh)
	
	# Detection area
	var area = Area3D.new()
	area.position = mesh.position
	area.position.y = 0.5
	
	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 0.8
	shape.height = 1.0
	col.shape = shape
	area.add_child(col)
	
	area.set_meta("hazard_type", "spike" if is_spike else "lava")
	area.set_meta("hex_coord", hex_coord)
	area.body_entered.connect(_on_hazard_entered.bind(area))
	area.body_exited.connect(_on_hazard_exited.bind(area))
	
	arena_root.add_child(area)

func create_spawn_visual(pos: Vector3, color: Color) -> void:
	var sphere = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.5
	sphere_mesh.height = 1.0
	sphere.mesh = sphere_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.7
	sphere.material_override = mat
	
	sphere.position = pos
	sphere.position.y = 1.0
	add_child(sphere)

func _physics_process(delta: float) -> void:
	# The Player3D handles its own movement through its components
	# We just need to handle hazard damage
	apply_hazard_damage(delta)

func apply_hazard_damage(delta: float) -> void:
	if hazards_touching.is_empty():
		return
		
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_damage_time >= damage_interval:
		for hazard in hazards_touching:
			if is_instance_valid(hazard):
				var hazard_type = hazard.get_meta("hazard_type", "")
				var damage = 15 if hazard_type == "spike" else 10
				
				# Use the player's actual take_damage method
				if test_player.has_method("take_damage"):
					test_player.take_damage(damage, self)
				
				last_damage_time = current_time
				break

func flash_damage() -> void:
	var mesh = test_player.get_node_or_null("MeshInstance3D")
	if mesh and mesh.material_override:
		var original_mat = mesh.material_override
		var flash_mat = StandardMaterial3D.new()
		flash_mat.albedo_color = Color(1.0, 0.3, 0.3)
		mesh.material_override = flash_mat
		
		await get_tree().create_timer(0.2).timeout
		
		if is_instance_valid(mesh):
			mesh.material_override = original_mat

func respawn() -> void:
	if spawn_points.size() > 0:
		var spawn_pos = spawn_points.pick_random()
		
		# Use player's respawn method if available
		if test_player.has_method("respawn"):
			test_player.respawn(spawn_pos)
		else:
			test_player.position = spawn_pos
			test_player.position.y = 2.0
			test_player.velocity = Vector3.ZERO
		
		hazard_label.text = "Respawned!"
		hazard_label.modulate = Color.GREEN

func _on_hazard_entered(body: Node3D, hazard: Area3D) -> void:
	if body == test_player:
		hazards_touching.append(hazard)
		var hazard_type = hazard.get_meta("hazard_type", "unknown")
		hazard_label.text = "On %s hazard!" % hazard_type.to_upper()
		hazard_label.modulate = Color.ORANGE

func _on_hazard_exited(body: Node3D, hazard: Area3D) -> void:
	if body == test_player:
		hazards_touching.erase(hazard)
		if hazards_touching.is_empty():
			hazard_label.text = "Safe"
			hazard_label.modulate = Color.WHITE

func update_health_display() -> void:
	if test_player and test_player.stats:
		var current = test_player.stats.current_health
		var max_hp = test_player.stats.max_health
		health_label.text = "Health: %d/%d" % [current, max_hp]
		health_label.modulate = Color.RED if current <= 30 else Color.YELLOW if current <= 60 else Color.GREEN
	else:
		health_label.text = "Health: N/A"

func _on_player_health_changed(new_health: int, max_health: int) -> void:
	update_health_display()
	if new_health <= 0:
		respawn()

func _input(event: InputEvent) -> void:
	# Handle respawn for testing
	if event.is_action_pressed("respawn_test"):
		respawn()

# Hex grid helper functions
func hex_to_world(hex_coord: Vector2i) -> Vector3:
	var q = hex_coord.x
	var r = hex_coord.y
	# Correct hex spacing - tiles should touch
	var x = sqrt(3.0) * q + sqrt(3.0)/2.0 * r
	var z = 3.0/2.0 * r
	return Vector3(x, 0, z)

func world_to_hex(world_pos: Vector3) -> Vector2i:
	var q = (sqrt(3.0)/3.0 * world_pos.x - 1.0/3.0 * world_pos.z)
	var r = (2.0/3.0 * world_pos.z)
	var s = -q - r
	
	var rq = round(q)
	var rr = round(r)
	var rs = round(s)
	
	var q_diff = abs(rq - q)
	var r_diff = abs(rr - r)
	var s_diff = abs(rs - s)
	
	if q_diff > r_diff and q_diff > s_diff:
		rq = -rr - rs
	elif r_diff > s_diff:
		rr = -rq - rs
	
	return Vector2i(int(rq), int(rr))

func create_hex_mesh() -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var verts = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	# Center vertex
	verts.push_back(Vector3.ZERO)
	uvs.push_back(Vector2(0.5, 0.5))
	normals.push_back(Vector3.UP)
	
	# Hex vertices
	for i in 6:
		var angle = (PI / 3.0) * i - PI / 6.0
		verts.push_back(Vector3(cos(angle), 0, sin(angle)))
		uvs.push_back(Vector2(0.5 + 0.5 * cos(angle), 0.5 + 0.5 * sin(angle)))
		normals.push_back(Vector3.UP)
	
	# Triangles
	for i in 6:
		indices.append_array([0, i + 1, (i % 6) + 2 if i < 5 else 1])
	
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh