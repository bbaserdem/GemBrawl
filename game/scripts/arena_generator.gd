## Arena Generator for hexagonal grid
## Generates arena layout with floor tiles and hazards
class_name ArenaGenerator
extends RefCounted

## Generate a hexagonal arena with the given radius
static func generate_hex_arena(tile_map: TileMap, radius: int) -> void:
	# Clear existing tiles
	tile_map.clear()
	
	# Generate hexagonal grid using axial coordinates
	for q in range(-radius, radius + 1):
		var r1 = max(-radius, -q - radius)
		var r2 = min(radius, -q + radius)
		
		for r in range(r1, r2 + 1):
			# Place floor tile at this position
			var coords = Vector2i(q, r)
			tile_map.set_cell(0, coords, 0, Vector2i(0, 0))

## Generate hazards on the hazard layer
static func generate_hazards(hazard_map: TileMap, radius: int, hazard_count: int) -> void:
	hazard_map.clear()
	
	var placed_hazards = 0
	var attempts = 0
	var max_attempts = hazard_count * 10
	
	while placed_hazards < hazard_count and attempts < max_attempts:
		attempts += 1
		
		# Random position within the arena
		var q = randi_range(-radius + 2, radius - 2)
		var r = randi_range(-radius + 2, radius - 2)
		
		# Check if position is valid (within hexagon bounds)
		if abs(q + r) <= radius - 2:
			var coords = Vector2i(q, r)
			
			# Check if tile is empty
			if hazard_map.get_cell_source_id(0, coords) == -1:
				# Randomly choose hazard type (1 = lava, 2 = spikes)
				var hazard_type = randi_range(1, 2)
				hazard_map.set_cell(0, coords, 0, Vector2i(hazard_type, 0))
				placed_hazards += 1

## Get spawn points for players (evenly distributed around the arena)
static func get_spawn_points(tile_map: TileMap, player_count: int, radius: int) -> Array[Vector2]:
	var spawn_points: Array[Vector2] = []
	var angle_step = TAU / player_count
	var spawn_radius = radius * 0.7  # Place spawns at 70% of arena radius
	
	for i in range(player_count):
		var angle = i * angle_step - PI / 2  # Start from top
		
		# Convert polar to axial hex coordinates
		var x = spawn_radius * cos(angle)
		var y = spawn_radius * sin(angle)
		
		# Convert to axial coordinates
		var q = round(x)
		var r = round(y)
		
		# Ensure within bounds
		if abs(q + r) <= radius:
			var world_pos = tile_map.map_to_local(Vector2i(q, r))
			spawn_points.append(world_pos)
	
	return spawn_points 