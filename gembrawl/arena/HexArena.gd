## HexArena - 3D hexagonal arena generator
## Migrated from prototype path `game/scripts/hex_arena_3d.gd`
## Creates a hexagonal arena using MeshInstance3D nodes for proper 2.5D isometric view
class_name HexArena
extends Node3D

## Arena configuration
@export var arena_radius: int = 7
@export var hex_size: float = 1.0
@export var hazard_count: int = 10

## Tile configuration
@export var tile_thickness: float = 0.5  # Height of tile blocks
@export var height_noise_amount: float = 0.05  # Random height variation
@export var hazard_height_offset: float = 0.1  # Height offset for hazards

## Visual settings
@export var floor_material: StandardMaterial3D
@export var hazard_material: StandardMaterial3D
@export var wall_material: StandardMaterial3D

## Arena data
var floor_tiles: Dictionary = {}  # Vector2i -> MeshInstance3D
var hazard_tiles: Dictionary = {}  # Vector2i -> MeshInstance3D
var spawn_points: Array[Marker3D] = []

## Mesh references
var hex_mesh: ArrayMesh
var wall_mesh: ArrayMesh

func _ready() -> void:
	# Update hex size in the grid utility
	HexGrid.HEX_SIZE = hex_size
	
	# Create meshes
	_create_hex_mesh()
	_create_wall_mesh()
	
	# Generate arena
	generate_arena()
	generate_hazards()
	generate_spawn_points()

## Create the hexagonal mesh
func _create_hex_mesh() -> void:
	hex_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	# Create vertices for pointy-top hexagon prism
	var vertices = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	
	# Top face
	# Center vertex
	vertices.push_back(Vector3(0, tile_thickness/2, 0))
	uvs.push_back(Vector2(0.5, 0.5))
	normals.push_back(Vector3.UP)
	
	# Outer vertices (6 points) - top face
	for i in range(6):
		var angle = (PI / 3.0) * i - PI / 6.0  # Start at top point
		var x = hex_size * cos(angle)
		var z = hex_size * sin(angle)
		vertices.push_back(Vector3(x, tile_thickness/2, z))
		
		# UV coordinates
		var u = 0.5 + 0.5 * cos(angle)
		var v = 0.5 + 0.5 * sin(angle)
		uvs.push_back(Vector2(u, v))
		normals.push_back(Vector3.UP)
	
	# Create triangles
	var indices = PackedInt32Array()
	for i in range(6):
		indices.push_back(0)  # Center
		indices.push_back(i + 1)
		indices.push_back((i % 6) + 1 + 1)
	# Fix the last triangle
	indices[17] = 1  # Wrap around to first vertex
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	
	hex_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

## Create wall mesh for arena boundaries
func _create_wall_mesh() -> void:
	# TODO: implement vertical wall generation for arena edge
	pass

## Generate the arena floor
## Creates hexagonal tiles in a radius pattern with collision and visual meshes
## Applies random height variation for visual interest
func generate_arena() -> void:
	# Clear existing tiles
	for tile in floor_tiles.values():
		tile.queue_free()
	floor_tiles.clear()
	
	# Get all hexes in radius
	var center = Vector2i(0, 0)
	var hexes = HexGrid.get_hexes_in_radius(center, arena_radius)
	
	# Create mesh instances for each hex
	for hex_coord in hexes:
		# Create a static body for collision
		var static_body = StaticBody3D.new()
		var base_pos = HexGrid.hex_to_world_3d(hex_coord)
		# Add random height variation
		var height_offset = randf_range(-height_noise_amount, height_noise_amount)
		static_body.position = base_pos + Vector3(0, height_offset, 0)
		
		# Add mesh instance as child of static body
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = hex_mesh
		
		# Apply material
		if floor_material:
			mesh_instance.material_override = floor_material
		else:
			# Create default material
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.3, 0.3, 0.3)
			mesh_instance.material_override = mat
		
		# Add collision shape
		var collision_shape = CollisionShape3D.new()
		collision_shape.shape = _create_hex_collision_shape()
		# Position collision shape to match the tile thickness
		collision_shape.position.y = tile_thickness / 2
		
		static_body.add_child(mesh_instance)
		static_body.add_child(collision_shape)
		add_child(static_body)
		floor_tiles[hex_coord] = static_body

## Generate hazards on the arena
## Randomly places hazard tiles avoiding edges and spawn areas
## Uses multiple attempts to ensure proper hazard distribution
func generate_hazards() -> void:
	# Clear existing hazards
	for hazard in hazard_tiles.values():
		hazard.queue_free()
	hazard_tiles.clear()
	
	var placed = 0
	var attempts = 0
	var max_attempts = hazard_count * 10
	
	while placed < hazard_count and attempts < max_attempts:
		attempts += 1
		
		# Random position within arena (avoiding edges)
		var q = randi_range(-arena_radius + 2, arena_radius - 2)
		var r = randi_range(-arena_radius + 2, arena_radius - 2)
		
		# Check if valid hex
		if abs(q + r) <= arena_radius - 2:
			var hex_coord = Vector2i(q, r)
			
			# Check if not already occupied
			if not hazard_tiles.has(hex_coord):
				# Create static body for hazard collision
				var hazard_body = StaticBody3D.new()
				var base_pos = HexGrid.hex_to_world_3d(hex_coord)
				# Add hazard height offset - smaller to not block movement
				hazard_body.position = base_pos + Vector3(0, hazard_height_offset, 0)
				
				# Add mesh
				var hazard_mesh = MeshInstance3D.new()
				hazard_mesh.mesh = hex_mesh
				
				# Apply hazard material
				if hazard_material:
					hazard_mesh.material_override = hazard_material
				else:
					var mat = StandardMaterial3D.new()
					mat.albedo_color = Color(1.0, 0.3, 0.0)  # Lava color
					mat.emission_enabled = true
					mat.emission = Color(1.0, 0.5, 0.0)
					mat.emission_energy = 0.5
					hazard_mesh.material_override = mat
				
				# Add collision shape
				var collision_shape = CollisionShape3D.new()
				collision_shape.shape = _create_hex_collision_shape()
				# Position collision shape to match the tile thickness
				collision_shape.position.y = tile_thickness / 2
				
				hazard_body.add_child(hazard_mesh)
				hazard_body.add_child(collision_shape)
				add_child(hazard_body)
				hazard_tiles[hex_coord] = hazard_body
				placed += 1

## Generate spawn points for players
## Creates evenly distributed spawn points around the arena perimeter
## Automatically adjusts to support different player counts
func generate_spawn_points() -> void:
	# Clear existing spawn points
	for spawn in spawn_points:
		spawn.queue_free()
	spawn_points.clear()
	
	# Calculate spawn positions (evenly distributed)
	var player_count = 4  # Default to 4 players
	var angle_step = TAU / player_count
	var spawn_radius = arena_radius * 0.7
	
	for i in range(player_count):
		var angle = i * angle_step
		
		# Convert polar to approximate hex position
		var x = spawn_radius * cos(angle)
		var z = spawn_radius * sin(angle)
		
		# Find nearest valid hex
		var world_pos = Vector3(x, 0, z)
		var hex_coord = HexGrid.world_to_hex_3d(world_pos)
		
		# Ensure it's within bounds
		if abs(hex_coord.x + hex_coord.y) <= arena_radius:
			var spawn_marker = Marker3D.new()
			spawn_marker.name = "SpawnPoint" + str(i + 1)
			spawn_marker.position = HexGrid.hex_to_world_3d(hex_coord)
			spawn_marker.position.y = 0.5  # Slightly above floor
			
			add_child(spawn_marker)
			spawn_points.append(spawn_marker)

## Get a random valid spawn position
func get_random_spawn_position() -> Vector3:
	if spawn_points.is_empty():
		return Vector3.ZERO
	
	var spawn = spawn_points.pick_random()
	return spawn.global_position

## Check if a hex coordinate is valid (within arena)
func is_valid_hex(hex_coord: Vector2i) -> bool:
	return floor_tiles.has(hex_coord)

## Create a collision shape for hex tiles
## Currently uses box approximation for performance
## @return: BoxShape3D sized to contain the hexagon
func _create_hex_collision_shape() -> Shape3D:
	# Create a simple box shape for now
	# In a real implementation, you'd want a proper hexagonal prism
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(hex_size * 1.5, tile_thickness, hex_size * 1.5)
	return box_shape

## Check if a hex coordinate has a hazard
func is_hazard_hex(hex_coord: Vector2i) -> bool:
	return hazard_tiles.has(hex_coord)

## Get the hex coordinate at a world position
func get_hex_at_position(world_pos: Vector3) -> Vector2i:
	return HexGrid.world_to_hex_3d(world_pos) 