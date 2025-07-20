## PlayerStats - Manages player health, lives, and respawn
## Handles defeat, respawn logic, and spectator mode
class_name PlayerStats
extends Node

## Life settings
@export var max_lives: int = 3
@export var respawn_delay: float = 3.0

## Current state
var is_alive: bool = true
var current_lives: int = 3
var is_spectator: bool = false

## References
var player: Player3D
var gem_data: Gem

## Signals
signal health_changed(new_health: int, max_health: int)
signal lives_changed(new_lives: int, max_lives: int)
signal defeated()
signal became_spectator()
signal respawning(time_until_respawn: float)

func _ready() -> void:
	player = get_parent() as Player3D
	if not player:
		push_error("PlayerStats must be a child of Player3D")
		queue_free()
	
	current_lives = max_lives

## Initialize stats component
func setup(gem: Gem) -> void:
	gem_data = gem
	if gem_data:
		health_changed.emit(gem_data.current_health, gem_data.max_health)

## Handle player defeat
func handle_defeat() -> void:
	is_alive = false
	defeated.emit()
	
	# Decrease lives
	current_lives -= 1
	lives_changed.emit(current_lives, max_lives)
	
	if current_lives > 0:
		# Start respawn process
		_start_respawn_timer()
	else:
		# No more lives - become spectator
		_become_spectator()

## Start respawn timer
func _start_respawn_timer() -> void:
	# Use SpawnManager if available
	var spawn_manager = get_node_or_null("/root/SpawnManager")
	if spawn_manager:
		print("Using SpawnManager for respawn")
		spawn_manager.request_respawn(player, respawn_delay)
	else:
		print("SpawnManager not found, using fallback")
		# Fallback to old respawn system
		respawning.emit(respawn_delay)
		
		# Hide player during respawn
		player.visible = false
		player.set_physics_process(false)
		
		# Countdown timer
		for i in range(int(respawn_delay)):
			await player.get_tree().create_timer(1.0).timeout
			respawning.emit(respawn_delay - i - 1)
		
		# Find a spawn point and respawn
		var spawn_point = _get_spawn_point()
		if spawn_point:
			respawn(spawn_point.global_position)

## Get a suitable spawn point
func _get_spawn_point() -> Node3D:
	# Look for spawn points in the scene
	var spawn_points = player.get_tree().get_nodes_in_group("spawn_points")
	if spawn_points.is_empty():
		# Try to get from arena
		var arena = player.get_node_or_null("/root/Main/HexArena")
		if arena and arena.has_method("get_random_spawn_position"):
			var marker = Marker3D.new()
			marker.global_position = arena.get_random_spawn_position()
			return marker
		push_warning("No spawn points found in scene!")
		return null
	
	# Choose a random spawn point
	return spawn_points[randi() % spawn_points.size()]

## Become a spectator
func _become_spectator() -> void:
	is_spectator = true
	became_spectator.emit()
	player.visible = false  # Hide the player model
	player.collision_layer = 0  # Disable all collisions
	player.collision_mask = 0

## Respawn the player at a given position
func respawn(spawn_position: Vector3) -> void:
	print("PlayerStats: respawn called, setting position to ", spawn_position)
	player.global_position = spawn_position
	player.velocity = Vector3.ZERO  # Reset velocity on respawn
	is_alive = true
	player.visible = true
	
	# Restore collision layers
	CombatLayers.setup_combat_body(player, CombatLayers.Layer.PLAYER)
	
	gem_data.current_health = gem_data.max_health
	health_changed.emit(gem_data.current_health, gem_data.max_health)
	player.set_physics_process(true)
	print("PlayerStats: Player respawned, is_alive = ", is_alive)
	
	# Update hex position if movement component exists
	var movement = player.get_node_or_null("Movement")
	if movement and movement.has_method("update_current_hex"):
		movement.update_current_hex()
	
	# Grant spawn invulnerability through combat component
	var combat = player.get_node_or_null("Combat")
	if combat and combat.has_method("start_invulnerability"):
		combat.start_invulnerability(2.0)  # Longer duration for respawn

## Check if player can take damage
func can_take_damage() -> bool:
	return is_alive and not is_spectator

## Get current health percentage
func get_health_percentage() -> float:
	if gem_data:
		return gem_data.get_health_percentage()
	return 0.0

## Heal the player
func heal(amount: int) -> void:
	if gem_data and is_alive:
		gem_data.heal(amount)
		health_changed.emit(gem_data.current_health, gem_data.max_health)