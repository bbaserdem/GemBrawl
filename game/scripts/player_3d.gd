## Player3D - 3D player controller for hex-based movement
## Uses CharacterBody3D for proper 3D physics and movement
class_name Player3D
extends CharacterBody3D

## Player properties
@export var gem_data: Gem
@export var player_id: int = 1
@export var is_local_player: bool = true

## Movement settings
@export var movement_speed: float = 5.0
@export var acceleration: float = 10.0
@export var friction: float = 10.0
@export var rotation_speed: float = 10.0

## Hex movement
@export var snap_to_hex: bool = false  # Whether to snap to hex centers
@export var hex_move_time: float = 0.2  # Time to move between hexes

## Combat state
var is_alive: bool = true
var invulnerable: bool = false
var invulnerability_duration: float = 0.5

## Skill state
var skill_ready: bool = true
var skill_cooldown_timer: float = 0.0

## Movement state
var current_hex: Vector2i = Vector2i.ZERO
var target_hex: Vector2i = Vector2i.ZERO
var hex_move_progress: float = 0.0
var is_moving_to_hex: bool = false

## Arena reference
var arena: HexArena3D

## Signals
signal health_changed(new_health: int, max_health: int)
signal defeated()
signal skill_used()
signal hex_entered(hex_coord: Vector2i)

## Visual nodes
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	# Find arena in scene
	arena = get_node_or_null("/root/Main/HexArena3D")
	
	# Apply gem properties
	if gem_data:
		movement_speed = gem_data.movement_speed / 100.0  # Convert to 3D scale
		
		# Apply gem visuals
		if mesh_instance:
			var material = StandardMaterial3D.new()
			material.albedo_color = gem_data.color
			mesh_instance.material_override = material
	
	# Initialize hex position
	_update_current_hex()
	
	# Ensure player starts at correct height
	global_position.y = 0.5

func _physics_process(delta: float) -> void:
	if not is_local_player or not is_alive:
		return
	
	if snap_to_hex:
		_handle_hex_movement(delta)
	else:
		_handle_free_movement(delta)
	
	# Update skill cooldown
	if not skill_ready:
		skill_cooldown_timer -= delta
		if skill_cooldown_timer <= 0:
			skill_ready = true

## Handle free movement (not snapped to hex grid)
func _handle_free_movement(delta: float) -> void:
	# Get input vector
	var input_vector = _get_movement_input()
	
	if input_vector.length() > 0:
		# Convert 2D input to 3D movement (fixed world directions)
		# Right = +X, Down = +Z (standard for top-down view)
		var movement_direction = Vector3(input_vector.x, 0, input_vector.y)
		
		# Apply movement
		velocity = velocity.move_toward(movement_direction * movement_speed, acceleration * delta)
		
		# Rotate to face movement direction
		if velocity.length() > 0.1:
			var look_direction = velocity.normalized()
			var target_rotation = atan2(look_direction.x, look_direction.z)
			rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
	else:
		# Apply friction
		velocity = velocity.move_toward(Vector3.ZERO, friction * delta)
	
	# Keep player at fixed height (no gravity needed for isometric view)
	velocity.y = 0
	
	move_and_slide()
	
	# Ensure player stays at correct height
	if global_position.y != 0.5:
		global_position.y = 0.5
	
	# Update current hex position
	var new_hex = HexGrid3D.world_to_hex_3d(global_position)
	if new_hex != current_hex:
		current_hex = new_hex
		hex_entered.emit(current_hex)

## Handle hex-snapped movement
func _handle_hex_movement(delta: float) -> void:
	if not is_moving_to_hex:
		# Get input and determine target hex
		var input_vector = _get_movement_input()
		
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
		var start_pos = HexGrid3D.hex_to_world_3d(current_hex)
		var end_pos = HexGrid3D.hex_to_world_3d(target_hex)
		global_position = start_pos.lerp(end_pos, hex_move_progress)
		global_position.y = 0.5  # Keep player above ground
		
		# Face movement direction
		if hex_move_progress < 0.5:
			var look_dir = (end_pos - start_pos).normalized()
			var target_rotation = atan2(look_dir.x, look_dir.z)
			rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)

## Get movement input from player
func _get_movement_input() -> Vector2:
	var input_vector = Vector2.ZERO
	
	# Gamepad input
	if Input.get_connected_joypads().size() > 0:
		input_vector.x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
		input_vector.y = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
		
		# Apply deadzone
		if input_vector.length() < 0.15:
			input_vector = Vector2.ZERO
	
	# Keyboard input (override gamepad if pressed)
	var keyboard_vector = Vector2.ZERO
	keyboard_vector.x = Input.get_axis("move_left", "move_right")
	keyboard_vector.y = Input.get_axis("move_up", "move_down")
	
	if keyboard_vector.length() > 0:
		input_vector = keyboard_vector
	
	# Normalize
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()
	
	return input_vector

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
func _update_current_hex() -> void:
	current_hex = HexGrid3D.world_to_hex_3d(global_position)

func _unhandled_input(event: InputEvent) -> void:
	if not is_local_player or not is_alive:
		return
	
	# Handle skill activation
	if event.is_action_pressed("use_skill") and skill_ready:
		use_skill()

## Take damage from an attack
func take_damage(damage: int, attacker: Node3D = null) -> void:
	if invulnerable or not is_alive:
		return
	
	var is_defeated = gem_data.take_damage(damage)
	health_changed.emit(gem_data.current_health, gem_data.max_health)
	
	if is_defeated:
		is_alive = false
		defeated.emit()
		set_physics_process(false)
		# TODO: Play death animation
		queue_free()
	else:
		# Trigger invulnerability
		invulnerable = true
		await get_tree().create_timer(invulnerability_duration).timeout
		invulnerable = false

## Use the gem's special skill
func use_skill() -> void:
	skill_ready = false
	skill_cooldown_timer = gem_data.skill_cooldown
	skill_used.emit()
	# Skill implementation handled by skill system

## Respawn the player at a given position
func respawn(spawn_position: Vector3) -> void:
	global_position = spawn_position
	global_position.y = 0.5  # Ensure correct height
	is_alive = true
	gem_data.current_health = gem_data.max_health
	health_changed.emit(gem_data.current_health, gem_data.max_health)
	set_physics_process(true)
	_update_current_hex()

## Set position to a specific hex
func set_hex_position(hex_coord: Vector2i) -> void:
	current_hex = hex_coord
	target_hex = hex_coord
	global_position = HexGrid3D.hex_to_world_3d(hex_coord)
	global_position.y = 0.5  # Player height 