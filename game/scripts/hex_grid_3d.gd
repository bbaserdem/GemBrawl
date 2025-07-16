## HexGrid3D - Utility class for hexagonal grid operations in 3D space
## Provides consistent coordinate conversion between hex (axial) and 3D world space
class_name HexGrid3D
extends RefCounted

## Hex grid configuration
static var HEX_SIZE: float = 1.0  # Size of hex from center to vertex
static var HEX_HEIGHT: float = 0.0  # Y position of the grid floor

## Get the width of a hex (flat to flat distance)
static func get_hex_width() -> float:
	return sqrt(3.0) * HexGrid3D.HEX_SIZE

## Get the height of a hex (point to point distance)  
static func get_hex_height() -> float:
	return 2.0 * HexGrid3D.HEX_SIZE

## Convert axial hex coordinates to 3D world position
## Uses pointy-top orientation
static func hex_to_world_3d(hex_coords: Vector2i) -> Vector3:
	var q = hex_coords.x
	var r = hex_coords.y
	
	# Pointy-top hex layout
	var x = HexGrid3D.HEX_SIZE * (sqrt(3.0) * q + sqrt(3.0)/2.0 * r)
	var z = HexGrid3D.HEX_SIZE * (3.0/2.0 * r)
	
	return Vector3(x, HexGrid3D.HEX_HEIGHT, z)

## Convert 3D world position to nearest hex coordinates
static func world_to_hex_3d(world_pos: Vector3) -> Vector2i:
	# Convert to fractional hex coordinates
	var q = (sqrt(3.0)/3.0 * world_pos.x - 1.0/3.0 * world_pos.z) / HexGrid3D.HEX_SIZE
	var r = (2.0/3.0 * world_pos.z) / HexGrid3D.HEX_SIZE
	
	# Convert to cube coordinates for rounding
	var s = -q - r
	
	# Round to nearest hex
	var rq = round(q)
	var rr = round(r)
	var rs = round(s)
	
	# Fix rounding errors
	var q_diff = abs(rq - q)
	var r_diff = abs(rr - r)
	var s_diff = abs(rs - s)
	
	if q_diff > r_diff and q_diff > s_diff:
		rq = -rr - rs
	elif r_diff > s_diff:
		rr = -rq - rs
	
	return Vector2i(int(rq), int(rr))

## Get all hex coordinates within a given radius from center
static func get_hexes_in_radius(center: Vector2i, radius: int) -> Array[Vector2i]:
	var hexes: Array[Vector2i] = []
	
	for q in range(-radius, radius + 1):
		var r1 = max(-radius, -q - radius)
		var r2 = min(radius, -q + radius)
		
		for r in range(r1, r2 + 1):
			hexes.append(center + Vector2i(q, r))
	
	return hexes

## Get neighboring hex coordinates
static func get_hex_neighbors(hex: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var directions = [
		Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
		Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)
	]
	
	for dir in directions:
		neighbors.append(hex + dir)
	
	return neighbors

## Calculate distance between two hexes
static func hex_distance(hex_a: Vector2i, hex_b: Vector2i) -> int:
	var diff = hex_b - hex_a
	return (abs(diff.x) + abs(diff.x + diff.y) + abs(diff.y)) / 2

## Get hex direction index (0-5) from one hex to another
static func get_hex_direction(from: Vector2i, to: Vector2i) -> int:
	var diff = to - from
	var directions = [
		Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
		Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)
	]
	
	for i in range(directions.size()):
		if diff == directions[i]:
			return i
	
	return -1  # Not adjacent

## Linear interpolation between hex positions in world space
static func hex_lerp_world(from_hex: Vector2i, to_hex: Vector2i, t: float) -> Vector3:
	var from_world = hex_to_world_3d(from_hex)
	var to_world = hex_to_world_3d(to_hex)
	return from_world.lerp(to_world, t) 