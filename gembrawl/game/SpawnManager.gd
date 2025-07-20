## SpawnManager - Singleton for managing spawn points
## Handles spawn point registration, selection logic, and respawn coordination
extends Node

## Spawn selection modes
enum SpawnMode {
	ASSIGNED,       ## Use player's assigned spawn point
	RANDOM,         ## Pick a random spawn point
	SEQUENTIAL,     ## Cycle through spawn points in order
	FARTHEST        ## Pick the farthest spawn point from all players
}

## Spawn point data
class SpawnPoint extends RefCounted:
	var node: Node3D
	var position: Vector3
	var is_occupied: bool = false
	var assigned_player: Player3D = null  # Player assigned to this spawn point
	var last_used_time: float = 0.0
	var index: int = -1  # Spawn point index for identification
	
	func _init(spawn_node: Node3D, spawn_index: int):
		node = spawn_node
		position = spawn_node.global_position
		index = spawn_index

## Settings
@export var spawn_mode: SpawnMode = SpawnMode.RANDOM
@export var spawn_cooldown: float = 3.0  # Time before a spawn point can be reused
@export var safe_spawn_radius: float = 5.0  # Minimum distance from enemies

## Registered spawn points
var spawn_points: Array[SpawnPoint] = []
var player_spawn_assignments: Dictionary = {}  # player -> SpawnPoint

## Active respawn queues
var respawn_queue: Array[Dictionary] = []
var active_respawn_timers: Dictionary = {}  # player -> timer

## Reference to the scene
var scene_root: Node

func _ready() -> void:
	# Wait for the scene tree to be fully ready
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame to ensure scene is loaded
	
	# Register spawn points after a short delay to ensure scene is fully loaded
	call_deferred("_setup_spawn_manager")

func _setup_spawn_manager() -> void:
	scene_root = get_tree().current_scene
	_register_spawn_points()

## Register all spawn points in the scene
func _register_spawn_points() -> void:
	spawn_points.clear()
	player_spawn_assignments.clear()
	
	# Find all nodes in spawn_points group
	var spawn_nodes = get_tree().get_nodes_in_group("spawn_points")
	
	var index = 0
	for spawn_node in spawn_nodes:
		if spawn_node is Node3D:
			var spawn_point = SpawnPoint.new(spawn_node, index)
			spawn_points.append(spawn_point)
			index += 1
	
	print("SpawnManager: Registered %d spawn points" % spawn_points.size())

## Get the best spawn point based on current mode and conditions
func get_spawn_point(player: Player3D) -> Vector3:
	var selected_spawn: SpawnPoint
	
	match spawn_mode:
		SpawnMode.ASSIGNED:
			# Use player's assigned spawn point
			if player_spawn_assignments.has(player):
				selected_spawn = player_spawn_assignments[player]
			else:
				# Assign a spawn point if not already assigned
				selected_spawn = _assign_spawn_point(player)
		
		SpawnMode.RANDOM:
			var available_spawns = _get_available_spawn_points()
			if not available_spawns.is_empty():
				selected_spawn = _get_random_spawn(available_spawns)
		
		SpawnMode.SEQUENTIAL:
			var available_spawns = _get_available_spawn_points()
			if not available_spawns.is_empty():
				selected_spawn = _get_sequential_spawn(available_spawns)
		
		SpawnMode.FARTHEST:
			var available_spawns = _get_available_spawn_points()
			if not available_spawns.is_empty():
				selected_spawn = _get_farthest_spawn(available_spawns, player)
	
	if selected_spawn:
		selected_spawn.last_used_time = Time.get_ticks_msec() / 1000.0
		return selected_spawn.position
	
	push_warning("No spawn point available!")
	return Vector3.ZERO

## Get available spawn points based on cooldown
func _get_available_spawn_points() -> Array[SpawnPoint]:
	var available: Array[SpawnPoint] = []
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# Use all spawn points that meet cooldown requirement
	for spawn in spawn_points:
		if current_time - spawn.last_used_time >= spawn_cooldown:
			available.append(spawn)
	
	# If no spawns available due to cooldown, return all spawns
	if available.is_empty():
		return spawn_points
	
	return available

## Assign a spawn point to a player
func _assign_spawn_point(player: Player3D) -> SpawnPoint:
	# Find an unassigned spawn point
	for spawn in spawn_points:
		if spawn.assigned_player == null:
			spawn.assigned_player = player
			player_spawn_assignments[player] = spawn
			print("SpawnManager: Assigned spawn point %d to player" % spawn.index)
			return spawn
	
	# If all spawn points are assigned, use the first one
	if spawn_points.size() > 0:
		var spawn = spawn_points[0]
		player_spawn_assignments[player] = spawn
		return spawn
	
	return null

## Random spawn selection
func _get_random_spawn(spawns: Array[SpawnPoint]) -> SpawnPoint:
	return spawns[randi() % spawns.size()]

## Get spawn farthest from all other players
func _get_farthest_spawn(spawns: Array[SpawnPoint], player: Player3D) -> SpawnPoint:
	var all_players = get_tree().get_nodes_in_group("players")
	
	# Remove self from list
	var other_players: Array = []
	for p in all_players:
		if p != player and p.is_alive:
			other_players.append(p)
	
	if other_players.is_empty():
		return _get_random_spawn(spawns)
	
	var best_spawn: SpawnPoint
	var best_distance: float = 0.0
	
	for spawn in spawns:
		var min_distance = INF
		for other_player in other_players:
			var distance = spawn.position.distance_to(other_player.global_position)
			min_distance = min(min_distance, distance)
		
		if min_distance > best_distance:
			best_distance = min_distance
			best_spawn = spawn
	
	return best_spawn if best_spawn else _get_random_spawn(spawns)

## Sequential spawn selection
var last_spawn_index: int = -1

func _get_sequential_spawn(spawns: Array[SpawnPoint]) -> SpawnPoint:
	last_spawn_index = (last_spawn_index + 1) % spawns.size()
	return spawns[last_spawn_index]


## Request respawn for a player
func request_respawn(player: Player3D, delay: float = -1.0) -> void:
	print("SpawnManager: Respawn requested for player")
	if delay < 0:
		delay = spawn_cooldown
	
	# Add to respawn queue
	var respawn_data = {
		"player": player,
		"time": Time.get_ticks_msec() / 1000.0 + delay
	}
	
	respawn_queue.append(respawn_data)
	
	# Start respawn timer
	_start_respawn_timer(player, delay)

## Start respawn timer for a player
func _start_respawn_timer(player: Player3D, delay: float) -> void:
	print("SpawnManager: Starting respawn timer for ", delay, " seconds")
	if active_respawn_timers.has(player):
		print("SpawnManager: Player already respawning!")
		return  # Already respawning
	
	# Hide player during respawn
	player.visible = false
	player.set_physics_process(false)
	
	# Emit countdown signals
	player.respawning.emit(delay)
	
	# Store that we're respawning this player
	active_respawn_timers[player] = true
	
	# Countdown and respawn
	var time_left = delay
	while time_left > 0:
		await get_tree().create_timer(1.0).timeout
		time_left -= 1
		if is_instance_valid(player):
			player.respawning.emit(time_left)
			print("SpawnManager: Countdown: ", time_left)
		else:
			print("SpawnManager: Player no longer valid during countdown")
			active_respawn_timers.erase(player)
			return
	
	print("SpawnManager: Timer finished, respawning now!")
	
	# Perform respawn
	if is_instance_valid(player):
		var spawn_pos = get_spawn_point(player)
		print("SpawnManager: Respawning player at position ", spawn_pos)
		if spawn_pos == Vector3.ZERO:
			print("ERROR: Invalid spawn position!")
			active_respawn_timers.erase(player)
			return
		player.respawn(spawn_pos)
		
		# Remove from active timers
		active_respawn_timers.erase(player)
	else:
		print("SpawnManager: Player instance no longer valid!")

## Add a spawn point dynamically
func add_spawn_point(position: Vector3) -> void:
	var marker = Marker3D.new()
	marker.global_position = position
	marker.add_to_group("spawn_points")
	
	scene_root.add_child(marker)
	
	# Re-register spawn points
	_register_spawn_points()

## Remove a spawn point
func remove_spawn_point(spawn_node: Node3D) -> void:
	for i in range(spawn_points.size()):
		if spawn_points[i].node == spawn_node:
			# Clear any player assignments
			var spawn = spawn_points[i]
			if spawn.assigned_player != null:
				player_spawn_assignments.erase(spawn.assigned_player)
			spawn_points.remove_at(i)
			break
	
	spawn_node.queue_free()

## Check if a position is safe for spawning
func is_spawn_position_safe(position: Vector3) -> bool:
	var all_players = get_tree().get_nodes_in_group("players")
	
	for player in all_players:
		if player.is_alive and position.distance_to(player.global_position) < safe_spawn_radius:
			return false
	
	return true

## Get spawn point info for debugging
func get_spawn_points_info() -> Dictionary:
	var info = {
		"total_spawns": spawn_points.size(),
		"active_respawns": active_respawn_timers.size(),
		"queued_respawns": respawn_queue.size(),
		"spawn_mode": SpawnMode.keys()[spawn_mode],
		"assigned_spawns": player_spawn_assignments.size()
	}
	
	return info

## Cycle a player to the next available spawn point (for testing)
func cycle_player_spawn(player: Player3D) -> void:
	print("SpawnManager: cycle_player_spawn called, spawn_points size: ", spawn_points.size())
	if not spawn_points.is_empty():
		var current_spawn = player_spawn_assignments.get(player)
		var current_index = -1
		
		print("SpawnManager: Current spawn assignment: ", current_spawn)
		
		# Find current spawn index
		if current_spawn:
			for i in range(spawn_points.size()):
				if spawn_points[i] == current_spawn:
					current_index = i
					break
			print("SpawnManager: Current spawn index: ", current_index)
		
		# Move to next spawn point
		var next_index = (current_index + 1) % spawn_points.size()
		var next_spawn = spawn_points[next_index]
		
		print("SpawnManager: Next spawn index: ", next_index, " (S", next_spawn.index, ")")
		
		# Clear old assignment
		if current_spawn:
			current_spawn.assigned_player = null
		
		# Set new assignment
		next_spawn.assigned_player = player
		player_spawn_assignments[player] = next_spawn
		
		print("SpawnManager: Player reassigned to spawn point %d" % next_spawn.index)
	else:
		print("SpawnManager: No spawn points available!")