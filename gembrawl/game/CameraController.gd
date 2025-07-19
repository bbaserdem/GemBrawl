## CameraController3D - 3D camera controller with tiltable isometric view
## Uses pivot-based rotation for smooth camera control
class_name CameraController3D
extends Node3D

## Camera settings
@export var camera_distance: float = 20.0
@export var camera_height: float = 15.0
@export var look_at_offset: Vector3 = Vector3.ZERO

## Tilt settings
@export var tilt_angle: float  # Degrees - will be set from initial rotation
@export var min_tilt: float = 15.0
@export var max_tilt: float = 75.0
@export var tilt_speed: float = 60.0  # Increased from 30 for more noticeable effect

## Zoom settings
@export var zoom_speed: float = 0.5  # Reduced for finer control
@export var min_zoom: float = 5.0
@export var max_zoom: float = 50.0

## Pan settings
@export var pan_speed: float = 10.0
@export var edge_pan_margin: float = 50.0  # Pixels from edge
@export var enable_edge_pan: bool = false

## Rotation settings
@export var rotation_speed: float = 90.0  # Degrees per second
@export var enable_rotation: bool = true  # Enable rotation for better control
var current_rotation: float = 0.0  # Current rotation angle in degrees

## Follow settings
@export var follow_target: Node3D
@export var follow_smoothness: float = 5.0
@export var enable_follow: bool = true

## Camera modes
enum CameraMode { PLAYER_FOCUSED, THIRD_PERSON, ARENA_FOCUSED }
var camera_mode: CameraMode = CameraMode.PLAYER_FOCUSED
var arena_center: Vector3 = Vector3.ZERO
var default_follow_zoom: float = 20.0  # Default zoom for follow mode
var default_arena_zoom: float = 35.0  # Default zoom for arena mode
var arena_camera_position: Vector3 = Vector3.ZERO  # Camera position in arena mode

## Camera nodes
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

## State
var current_zoom: float
var is_panning: bool = false
var pan_start_pos: Vector2
var pan_start_cam_pos: Vector3
var initial_pivot_rotation: Vector3  # Store initial rotation
var initial_tilt_degrees: float  # Store initial tilt in degrees
var is_initialized: bool = false  # Track initialization state
var current_tilt: float  # Actual rendered tilt (smoothly interpolated)
var local_player_check_timer: float = 0.0  # Timer for periodic local player checks

func _ready() -> void:
	# Initialize camera position
	current_zoom = camera_distance
	
	# Store initial pivot rotation
	if camera_pivot:
		initial_pivot_rotation = camera_pivot.rotation
		# Calculate the initial tilt angle from the rotation
		initial_tilt_degrees = -rad_to_deg(initial_pivot_rotation.x)
		# Set our tilt angle to match the initial rotation
		tilt_angle = initial_tilt_degrees
		current_tilt = tilt_angle  # Initialize current tilt
	
	is_initialized = true
	_update_camera_position()
	
	# Set up input
	set_process_input(true)
	set_process_unhandled_input(true)
	
	# Find the local player if not set
	if not follow_target:
		find_local_player()
	
	# Set arena center (0,0,0 for our hex arena)
	arena_center = Vector3.ZERO

func _process(delta: float) -> void:
	# Handle continuous input (keyboard and gamepad camera control)
	_handle_keyboard_input(delta)
	_handle_gamepad_camera(delta)
	
	# Smoothly interpolate tilt
	if is_initialized and abs(current_tilt - tilt_angle) > 0.01:
		var old_current = current_tilt
		current_tilt = lerp(current_tilt, tilt_angle, 10.0 * delta)
		_update_camera_position()
	
	# Handle edge panning
	if enable_edge_pan:
		_handle_edge_pan(delta)
	
	# Periodically check if we need to update the local player (every 0.5 seconds)
	local_player_check_timer += delta
	if local_player_check_timer >= 0.5:
		local_player_check_timer = 0.0
		# Check if we should track a different player
		if not follow_target or (follow_target.has_method("get") and not follow_target.get("is_local_player")):
			find_local_player()
	
	# Camera positioning based on mode
	match camera_mode:
		CameraMode.PLAYER_FOCUSED:
			# Camera follows player with fixed orientation
			if enable_follow and follow_target and is_instance_valid(follow_target):
				var target_pos = follow_target.global_position + look_at_offset
				global_position = global_position.lerp(target_pos, follow_smoothness * delta)
				
				# Keep rotation fixed (allow manual control with Q/E or right stick)
				# Update camera with current zoom
				_update_camera_position()
					
		CameraMode.THIRD_PERSON:
			# Camera follows player and rotates to keep player facing forward
			if enable_follow and follow_target and is_instance_valid(follow_target):
				var target_pos = follow_target.global_position + look_at_offset
				global_position = global_position.lerp(target_pos, follow_smoothness * delta)
				
				# Rotate camera to be behind the player (add 180 degrees)
				var player_rotation = follow_target.rotation.y + PI
				var target_rotation = player_rotation
				
				# Apply rotation differently from manual rotation
				rotation.y = lerp_angle(rotation.y, target_rotation, delta * 12.0)
				current_rotation = rad_to_deg(rotation.y)  # Keep current_rotation in sync
				
				# Allow zoom control in third person (don't force to 15.0)
				_update_camera_position()
					
		CameraMode.ARENA_FOCUSED:
			# Static camera focused on arena center
			# Zoom controls move camera forward/backward instead of zooming
			var tilt_offset = 12.0 * sin(deg_to_rad(tilt_angle))
			var base_position = arena_center + Vector3(0, 0, tilt_offset)
			
			# Initialize arena camera position if needed
			if arena_camera_position == Vector3.ZERO:
				arena_camera_position = base_position
			
			global_position = global_position.lerp(arena_camera_position, follow_smoothness * delta * 2.0)
			
			# Fixed zoom level for arena mode
			if abs(current_zoom - default_arena_zoom) > 0.1:
				current_zoom = lerp(current_zoom, default_arena_zoom, delta * 2.0)
				_update_camera_position()

func _unhandled_input(event: InputEvent) -> void:
	# Toggle camera mode with R3 (right stick press)
	if event is InputEventJoypadButton:
		if event.button_index == JOY_BUTTON_RIGHT_STICK and event.pressed:
			_toggle_camera_mode()
	
	# Zoom (Mouse wheel)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_adjust_zoom(-zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_adjust_zoom(zoom_speed)
	
	# Pan (Middle mouse)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				is_panning = true
				pan_start_pos = event.position
				pan_start_cam_pos = global_position
			else:
				is_panning = false
	
	# Pan movement
	if event is InputEventMouseMotion and is_panning:
		var delta = event.position - pan_start_pos
		var pan_offset = Vector3(-delta.x, 0, -delta.y) * pan_speed * 0.01
		
		# Transform pan offset by camera rotation
		pan_offset = pan_offset.rotated(Vector3.UP, rotation.y)
		global_position = pan_start_cam_pos + pan_offset

func _handle_keyboard_input(delta: float) -> void:
	# Camera rotation (Q/E) - only when enabled
	if enable_rotation:
		if Input.is_action_pressed("rotate_camera_left"):
			rotation.y += deg_to_rad(rotation_speed * delta)
		elif Input.is_action_pressed("rotate_camera_right"):
			rotation.y -= deg_to_rad(rotation_speed * delta)

## Handle gamepad camera controls
## Processes right stick for rotation/zoom and shoulder buttons for tilt
## @param delta: Frame time for smooth movement
func _handle_gamepad_camera(delta: float) -> void:
	# Right stick camera controls
	if Input.get_connected_joypads().size() > 0:
		var right_stick_x = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
		var right_stick_y = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
		
		# Apply deadzone
		if abs(right_stick_x) < 0.15:
			right_stick_x = 0
		if abs(right_stick_y) < 0.15:
			right_stick_y = 0
		
		# Right stick Y-axis: Zoom (up = zoom in, down = zoom out)
		if right_stick_y != 0:
			_adjust_zoom(zoom_speed * right_stick_y)  # Positive for intuitive control (up = negative axis = zoom in)
		
		# Right stick X-axis: Rotate camera around scene
		if right_stick_x != 0 and enable_rotation:
			current_rotation += rotation_speed * right_stick_x * delta
			_update_camera_position()
		
		# Handle camera tilt with L1/R1
		if Input.is_action_pressed("tilt_camera_up"):
			_adjust_tilt(tilt_speed * delta)
		elif Input.is_action_pressed("tilt_camera_down"):
			_adjust_tilt(-tilt_speed * delta)

## Handle edge-of-screen panning
## Moves camera when mouse is near screen edges
## @param delta: Frame time for smooth movement
func _handle_edge_pan(delta: float) -> void:
	var viewport = get_viewport()
	var mouse_pos = viewport.get_mouse_position()
	var screen_size = viewport.get_visible_rect().size
	
	var pan_dir = Vector3.ZERO
	
	# Check edges
	if mouse_pos.x < edge_pan_margin:
		pan_dir.x -= 1
	elif mouse_pos.x > screen_size.x - edge_pan_margin:
		pan_dir.x += 1
	
	if mouse_pos.y < edge_pan_margin:
		pan_dir.z -= 1
	elif mouse_pos.y > screen_size.y - edge_pan_margin:
		pan_dir.z += 1
	
	if pan_dir.length() > 0:
		pan_dir = pan_dir.normalized()
		# Transform by camera rotation
		pan_dir = pan_dir.rotated(Vector3.UP, rotation.y)
		global_position += pan_dir * pan_speed * delta

func _adjust_tilt(delta_tilt: float) -> void:
	# Simply update the target tilt angle - smoothing happens in _process
	tilt_angle = clamp(tilt_angle + delta_tilt, min_tilt, max_tilt)

func _adjust_zoom(delta_zoom: float) -> void:
	if camera_mode == CameraMode.ARENA_FOCUSED:
		# In arena mode, zoom controls move camera forward/backward
		var forward = -transform.basis.z
		arena_camera_position += forward * delta_zoom * 2.0
	else:
		# Normal zoom behavior for other modes
		current_zoom = clamp(current_zoom + delta_zoom, min_zoom, max_zoom)
		_update_camera_position()

## Update camera position and orientation
## Applies rotation, tilt, and zoom to the camera pivot system
func _update_camera_position() -> void:
	if not is_initialized or not camera_pivot or not camera:
		return
	
	# Update camera rotation around Y axis
	rotation.y = deg_to_rad(current_rotation)
	
	# Update pivot tilt - use negative because rotation.x is inverted in Godot
	var target_rotation = -deg_to_rad(current_tilt)
	camera_pivot.rotation.x = target_rotation  # Use interpolated tilt
	# Preserve Y and Z rotations from initial setup
	camera_pivot.rotation.y = initial_pivot_rotation.y
	camera_pivot.rotation.z = initial_pivot_rotation.z
	
	# Update camera distance
	camera.position = Vector3(0, 0, current_zoom)

## Set the camera to follow a target
func set_follow_target(target: Node3D) -> void:
	follow_target = target
	enable_follow = true

## Get the current tilt angle in degrees
func get_tilt_angle() -> float:
	return tilt_angle

## Get the current zoom level
func get_zoom_level() -> float:
	return current_zoom

## Center camera on a world position
func center_on_position(world_pos: Vector3) -> void:
	global_position = world_pos + look_at_offset

## Shake the camera (for impacts, etc.)
func shake(intensity: float = 1.0, duration: float = 0.5) -> void:
	# Simple camera shake implementation
	var original_pos = global_position
	var shake_timer = 0.0
	
	while shake_timer < duration:
		var offset = Vector3(
			randf_range(-intensity, intensity),
			0,
			randf_range(-intensity, intensity)
		)
		global_position = original_pos + offset
		
		shake_timer += get_process_delta_time()
		await get_tree().process_frame
	
	global_position = original_pos

## Toggle between camera modes
func _toggle_camera_mode() -> void:
	# Cycle through modes: PLAYER_FOCUSED -> THIRD_PERSON -> ARENA_FOCUSED -> PLAYER_FOCUSED
	match camera_mode:
		CameraMode.PLAYER_FOCUSED:
			camera_mode = CameraMode.THIRD_PERSON
			enable_follow = true
			enable_rotation = false  # Disable manual rotation in third person
			print("Camera Mode: THIRD PERSON")
		CameraMode.THIRD_PERSON:
			camera_mode = CameraMode.ARENA_FOCUSED
			enable_follow = false
			enable_rotation = true
			# Initialize arena camera position
			arena_camera_position = arena_center + Vector3(0, 0, 12.0)
			print("Camera Mode: ARENA FOCUSED")
		CameraMode.ARENA_FOCUSED:
			camera_mode = CameraMode.PLAYER_FOCUSED
			enable_follow = true
			enable_rotation = true
			# Reset zoom to follow default
			current_zoom = default_follow_zoom
			_update_camera_position()
			print("Camera Mode: PLAYER FOCUSED")

## Set the arena center position
func set_arena_center(center: Vector3) -> void:
	arena_center = center

## Find and set the player with is_local_player = true as the follow target
func find_local_player() -> void:
	# First check players in the "players" group
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if player.has_method("get") and player.get("is_local_player") == true:
			set_follow_target(player)
			print("CameraController: Found local player in group: ", player.name)
			return
	
	# If no player in group, check all children of the current scene
	var root = get_tree().current_scene
	if root:
		for child in root.get_children():
			if child.has_method("get") and child.get("is_local_player") == true:
				set_follow_target(child)
				print("CameraController: Found local player: ", child.name)
				return
	
	# Debug message suppressed - no local player is expected in some test scenes 