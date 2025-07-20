## PlayerMovement - Handles all player movement logic
## Manages both free movement and hex-based movement systems
class_name PlayerMovement
extends Node

# Ensure HexGrid is loaded and available as constant
const HexGrid = preload("res://arena/HexGrid.gd")

## Movement settings
@export var movement_speed: float = 5.0
@export var acceleration: float = 10.0
@export var friction: float = 10.0
@export var rotation_speed: float = 6.0  # Reduced from 10.0 for smoother turning

## Jump and gravity settings
@export var jump_force: float = 10.0
@export var gravity: float = 20.0
@export var max_fall_speed: float = 30.0
@export var ground_height: float = 0.5
@export var step_height: float = 0.3

## Hex movement settings
@export var snap_to_hex: bool = false
@export var hex_move_time: float = 0.2

## Movement state
var current_hex: Vector2i = Vector2i.ZERO
var target_hex: Vector2i = Vector2i.ZERO
var hex_move_progress: float = 0.0
var is_moving_to_hex: bool = false

## References - untyped to avoid circular dependencies
var player: CharacterBody3D
var arena  # HexArena reference

## Signals
signal hex_entered(hex_coord: Vector2i)

func _ready() -> void:
	player = get_parent() as CharacterBody3D
	if not player:
		push_error("PlayerMovement must be a child of CharacterBody3D")
		queue_free()

## Initialize movement component
func setup(arena_ref) -> void:
	arena = arena_ref
	update_current_hex()

## Handle movement based on current mode
func process_movement(delta: float, input_vector: Vector2) -> void:
	if snap_to_hex:
		_handle_hex_movement(delta, input_vector)
	else:
		_handle_free_movement(delta, input_vector)

## Handle free movement (not snapped to hex grid)
func _handle_free_movement(delta: float, input_vector: Vector2) -> void:
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y -= gravity * delta
		player.velocity.y = max(player.velocity.y, -max_fall_speed)
	
	# Handle jumping
	if player.is_on_floor() and Input.is_action_just_pressed("jump"):
		player.velocity.y = jump_force
	
	if input_vector.length() > 0:
		# Get camera rotation for camera-relative movement
		var camera = player.get_viewport().get_camera_3d()
		var camera_transform = camera.get_global_transform()
		
		# Get camera forward and right vectors (projected on XZ plane)
		var cam_forward = -camera_transform.basis.z
		cam_forward.y = 0
		cam_forward = cam_forward.normalized()
		
		var cam_right = camera_transform.basis.x
		cam_right.y = 0
		cam_right = cam_right.normalized()
		
		# Convert 2D input to 3D movement relative to camera
		var movement_direction = cam_forward * -input_vector.y + cam_right * input_vector.x
		
		# Apply horizontal movement
		var horizontal_velocity = Vector3(player.velocity.x, 0, player.velocity.z)
		horizontal_velocity = horizontal_velocity.move_toward(movement_direction * movement_speed, acceleration * delta)
		player.velocity.x = horizontal_velocity.x
		player.velocity.z = horizontal_velocity.z
		
		# Rotate to face movement direction
		if horizontal_velocity.length() > 0.1:
			var look_direction = horizontal_velocity.normalized()
			var target_rotation = atan2(look_direction.x, look_direction.z)
			player.rotation.y = lerp_angle(player.rotation.y, target_rotation, rotation_speed * delta)
	else:
		# Apply friction to horizontal movement only
		var horizontal_velocity = Vector3(player.velocity.x, 0, player.velocity.z)
		horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO, friction * delta)
		player.velocity.x = horizontal_velocity.x
		player.velocity.z = horizontal_velocity.z
	
	player.move_and_slide()
	
	# Update current hex position
	var new_hex = HexGrid.world_to_hex_3d(player.global_position)
	if new_hex != current_hex:
		current_hex = new_hex
		hex_entered.emit(current_hex)

## Handle hex-snapped movement
func _handle_hex_movement(delta: float, input_vector: Vector2) -> void:
	# Apply gravity regardless of hex movement
	if not player.is_on_floor():
		player.velocity.y -= gravity * delta
		player.velocity.y = max(player.velocity.y, -max_fall_speed)
	
	# Handle jumping
	if player.is_on_floor() and Input.is_action_just_pressed("jump"):
		player.velocity.y = jump_force
		
	if not is_moving_to_hex:
		# Get input and determine target hex
		if input_vector.length() > 0.5:
			# Determine best hex direction based on input
			var best_dir = _get_hex_direction_from_input(input_vector)
			if best_dir != -1:
				var directions = [
					Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
					Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)
				]
				
				var new_hex = current_hex + directions[best_dir]
				
				# Check if target hex is valid
				if arena and arena.is_valid_hex(new_hex) and not arena.is_hazard_hex(new_hex):
					target_hex = new_hex
					is_moving_to_hex = true
					hex_move_progress = 0.0
	
	# Perform hex movement
	if is_moving_to_hex:
		hex_move_progress += delta / hex_move_time
		
		if hex_move_progress >= 1.0:
			# Movement complete
			hex_move_progress = 1.0
			is_moving_to_hex = false
			current_hex = target_hex
			hex_entered.emit(current_hex)
		
		# Interpolate position
		var start_pos = HexGrid.hex_to_world_3d(current_hex)
		var end_pos = HexGrid.hex_to_world_3d(target_hex)
		var interpolated_pos = start_pos.lerp(end_pos, hex_move_progress)
		player.global_position.x = interpolated_pos.x
		player.global_position.z = interpolated_pos.z
		# Let gravity handle Y position
		
		# Face movement direction
		if hex_move_progress < 0.5:
			var look_dir = (end_pos - start_pos).normalized()
			var target_rotation = atan2(look_dir.x, look_dir.z)
			player.rotation.y = lerp_angle(player.rotation.y, target_rotation, rotation_speed * delta)
	
	# Always apply physics to handle collisions and gravity
	player.move_and_slide()

## Convert input vector to hex direction (0-5)
func _get_hex_direction_from_input(input: Vector2) -> int:
	# Convert input angle to hex direction
	var angle = atan2(input.y, input.x)
	var hex_angle = fmod(angle + TAU, TAU)  # Normalize to 0-TAU
	
	# Hex directions (pointy-top, starting from right)
	# 0: Right (0°), 1: Down-Right (60°), 2: Down-Left (120°)
	# 3: Left (180°), 4: Up-Left (240°), 5: Up-Right (300°)
	
	var sector = int(round(hex_angle / (TAU / 6.0))) % 6
	return sector

## Update current hex position
func update_current_hex() -> void:
	current_hex = HexGrid.world_to_hex_3d(player.global_position)

## Set position to a specific hex
func set_hex_position(hex_coord: Vector2i) -> void:
	current_hex = hex_coord
	target_hex = hex_coord
	var hex_pos = HexGrid.hex_to_world_3d(hex_coord)
	player.global_position = hex_pos
	player.global_position.y = max(hex_pos.y + ground_height, player.global_position.y)

## Handle spectator movement (free-fly camera)
func handle_spectator_movement(delta: float, input_vector: Vector2) -> void:
	# Allow spectator to fly freely
	var camera = player.get_viewport().get_camera_3d()
	if camera:
		var camera_transform = camera.get_global_transform()
		
		# Get camera vectors
		var cam_forward = -camera_transform.basis.z
		var cam_right = camera_transform.basis.x
		var cam_up = camera_transform.basis.y
		
		# Convert input to 3D movement
		var movement = Vector3.ZERO
		movement += cam_forward * -input_vector.y
		movement += cam_right * input_vector.x
		
		# Vertical movement
		if Input.is_action_pressed("jump"):
			movement += cam_up
		if Input.is_action_pressed("crouch"):
			movement -= cam_up
		
		# Apply movement
		player.global_position += movement.normalized() * movement_speed * 2.0 * delta