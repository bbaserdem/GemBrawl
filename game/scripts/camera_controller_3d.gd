## CameraController3D - 3D camera controller with tiltable isometric view
## Uses pivot-based rotation for smooth camera control
class_name CameraController3D
extends Node3D

## Camera settings
@export var camera_distance: float = 20.0
@export var camera_height: float = 15.0
@export var look_at_offset: Vector3 = Vector3.ZERO

## Tilt settings
@export var tilt_angle: float = 45.0  # Degrees
@export var min_tilt: float = 15.0
@export var max_tilt: float = 75.0
@export var tilt_speed: float = 30.0  # Degrees per second

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
@export var enable_rotation: bool = false  # Disabled for isometric view

## Follow settings
@export var follow_target: Node3D
@export var follow_smoothness: float = 5.0
@export var enable_follow: bool = true

## Camera modes
enum CameraMode { STATIC, FOLLOW_PLAYER }
var camera_mode: CameraMode = CameraMode.FOLLOW_PLAYER
var arena_center: Vector3 = Vector3.ZERO

## Camera nodes
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

## State
var current_zoom: float
var is_panning: bool = false
var pan_start_pos: Vector2
var pan_start_cam_pos: Vector3

func _ready() -> void:
	# Initialize camera position
	current_zoom = camera_distance
	_update_camera_position()
	
	# Set up input
	set_process_input(true)
	set_process_unhandled_input(true)
	
	# Find the player if not set
	if not follow_target:
		follow_target = get_node_or_null("../Player3D")
		if follow_target:
			print("Found player for camera follow")
	
	# Set arena center (0,0,0 for our hex arena)
	arena_center = Vector3.ZERO

func _process(delta: float) -> void:
	# Handle continuous input (keyboard and gamepad camera control)
	_handle_keyboard_input(delta)
	_handle_gamepad_camera(delta)
	
	# Handle edge panning
	if enable_edge_pan:
		_handle_edge_pan(delta)
	
	# Camera positioning based on mode
	match camera_mode:
		CameraMode.STATIC:
			# Center on arena - adjust position based on tilt angle
			# Move camera south (positive Z) to compensate for tilt
			var tilt_offset = 12.0 * sin(deg_to_rad(tilt_angle))  # More offset for steeper angles
			var static_offset = Vector3(0, 0, tilt_offset)
			global_position = global_position.lerp(arena_center + static_offset, follow_smoothness * delta)
			# Zoom out more in static mode for full arena view
			if current_zoom < 35:
				current_zoom = lerp(current_zoom, 35.0, delta * 2.0)
				_update_camera_position()
		CameraMode.FOLLOW_PLAYER:
			# Follow target
			if follow_target:
				var target_pos = follow_target.global_position + look_at_offset
				global_position = global_position.lerp(target_pos, follow_smoothness * delta)

func _unhandled_input(event: InputEvent) -> void:
	# Camera tilt (Page Up/Down only - removed R1/R2)
	if event.is_action_pressed("ui_page_up"):
		_adjust_tilt(-tilt_speed / 10.0)
	elif event.is_action_pressed("ui_page_down"):
		_adjust_tilt(tilt_speed / 10.0)
	
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
			_adjust_zoom(-zoom_speed * right_stick_y)  # Negative for intuitive control
		
		# Right stick X-axis: Camera tilt (left = tilt up, right = tilt down)
		if right_stick_x != 0:
			_adjust_tilt(tilt_speed * right_stick_x * delta)

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
	tilt_angle = clamp(tilt_angle + delta_tilt, min_tilt, max_tilt)
	_update_camera_position()

func _adjust_zoom(delta_zoom: float) -> void:
	current_zoom = clamp(current_zoom + delta_zoom, min_zoom, max_zoom)
	_update_camera_position()

func _update_camera_position() -> void:
	if not camera_pivot or not camera:
		return
	
	# Update pivot tilt
	camera_pivot.rotation.x = -deg_to_rad(tilt_angle)
	
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
	match camera_mode:
		CameraMode.STATIC:
			camera_mode = CameraMode.FOLLOW_PLAYER
			print("Camera Mode: Follow Player")
		CameraMode.FOLLOW_PLAYER:
			camera_mode = CameraMode.STATIC
			print("Camera Mode: Static (Arena Center)")

## Set the arena center position
func set_arena_center(center: Vector3) -> void:
	arena_center = center 