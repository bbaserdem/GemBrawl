## PlayerInput - Handles all player input processing
## Manages keyboard, gamepad, and action inputs
class_name PlayerInput
extends Node

## Input settings
@export var player_index: int = 0  # Which player slot this input belongs to
@export var gamepad_deadzone: float = 0.15
@export var enable_gamepad: bool = true
@export var enable_keyboard: bool = true

## References
var player  ## IPlayer interface - injected from parent
var device_id: int = -1  # Device ID from ControllerManager (-1 = keyboard)

## Cached input state
var current_movement_input: Vector2 = Vector2.ZERO
var is_jump_pressed: bool = false
var is_skill_pressed: bool = false
var _was_jump_pressed: bool = false  # For tracking just_pressed state
var _was_skill_pressed: bool = false  # For tracking just_pressed state

# Player is now injected from parent instead of getting from get_parent()

func _ready() -> void:
	# Player is injected from parent, no need to get_parent()
	
	# Get assigned device from ControllerManager
	if has_node("/root/ControllerManager"):
		var controller_manager = get_node("/root/ControllerManager")
		# In single-player mode, player 0 accepts all inputs
		if controller_manager.is_single_player_mode() and player_index == 0:
			device_id = -2  # Special value for "accept all inputs"
			print("[PlayerInput] Single-player mode enabled - accepting all inputs")
		else:
			device_id = controller_manager.get_player_device_id(player_index)
	
	set_process_unhandled_input(true)

## Get movement input from player
func get_movement_input() -> Vector2:
	var input_vector = Vector2.ZERO
	
	if device_id == -2:  # Single-player mode - accept all inputs
		# Use the standard input actions that accept any device
		input_vector.x = Input.get_axis("move_left", "move_right")
		input_vector.y = Input.get_axis("move_up", "move_down")
		
	elif device_id >= 0 and enable_gamepad:  # Specific gamepad input
		# Check if the device is still connected
		var connected_joypads = Input.get_connected_joypads()
		if device_id in connected_joypads:
			input_vector.x = Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X)
			input_vector.y = Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y)
			
			# Apply deadzone
			if input_vector.length() < gamepad_deadzone:
				input_vector = Vector2.ZERO
	
	elif device_id == -1 and player_index == 0 and enable_keyboard:  # Keyboard only for P1
		# Use keyboard-specific input checks to avoid gamepad interference
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
			input_vector.x -= 1.0
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
			input_vector.x += 1.0
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
			input_vector.y -= 1.0
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
			input_vector.y += 1.0
	
	# Normalize
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()
	
	current_movement_input = input_vector
	return input_vector

## Check if jump action is pressed
func is_jump_action_pressed() -> bool:
	if device_id == -2:  # Single-player mode
		# Use standard input action that accepts any device
		return Input.is_action_just_pressed("jump")
	
	# We need to track just_pressed state manually for specific devices
	# since Godot's is_joy_button_just_pressed doesn't exist
	# This is handled through _unhandled_input and the is_jump_pressed flag
	if device_id >= 0:  # Gamepad
		# Return true only on the frame the button was pressed
		var result = is_jump_pressed and not _was_jump_pressed
		_was_jump_pressed = is_jump_pressed
		return result
	elif device_id == -1 and player_index == 0:  # Keyboard
		# Use the tracked state from _unhandled_input to avoid gamepad interference
		var result = is_jump_pressed and not _was_jump_pressed
		_was_jump_pressed = is_jump_pressed
		return result
	return false

## Check if skill action is pressed
func is_skill_action_pressed() -> bool:
	if device_id == -2:  # Single-player mode
		# Use standard input action that accepts any device
		return Input.is_action_just_pressed("use_skill")
	
	# Same approach for skill button
	if device_id >= 0:  # Gamepad
		var result = is_skill_pressed and not _was_skill_pressed
		_was_skill_pressed = is_skill_pressed
		return result
	elif device_id == -1 and player_index == 0:  # Keyboard
		# Use the tracked state from _unhandled_input to avoid gamepad interference
		var result = is_skill_pressed and not _was_skill_pressed
		_was_skill_pressed = is_skill_pressed
		return result
	return false

## Handle unhandled input events
func _unhandled_input(event: InputEvent) -> void:
	if not player.is_local_player:
		return
	
	# In single-player mode, we don't need to track button states manually
	if device_id == -2:
		return
	
	# Handle gamepad events ONLY for the specific assigned device
	if event is InputEventJoypadButton and device_id >= 0:
		# Only process if this event is from our assigned device
		if event.device != device_id:
			return
			
		if event.button_index == JOY_BUTTON_B:
			is_jump_pressed = event.pressed
		elif event.button_index == JOY_BUTTON_A:
			is_skill_pressed = event.pressed
	
	# Handle keyboard events only for player with keyboard assignment (device_id = -1)
	elif device_id == -1 and player_index == 0 and event is InputEventKey:
		# Only process keyboard events
		# Check both keycode and physical_keycode for better compatibility
		if event.physical_keycode == KEY_SHIFT or event.keycode == KEY_SHIFT:
			is_jump_pressed = event.pressed
		elif event.physical_keycode == KEY_SPACE or event.keycode == KEY_SPACE:
			is_skill_pressed = event.pressed

## Get camera-relative movement direction
func get_camera_relative_movement(input_vector: Vector2) -> Vector3:
	if input_vector.length() == 0:
		return Vector3.ZERO
	
	var camera = player.get_viewport().get_camera_3d() if player else null
	if not camera:
		return Vector3(input_vector.x, 0, input_vector.y)
	
	var camera_transform = camera.get_global_transform()
	
	# Get camera forward and right vectors (projected on XZ plane)
	var cam_forward = -camera_transform.basis.z
	cam_forward.y = 0
	cam_forward = cam_forward.normalized()
	
	var cam_right = camera_transform.basis.x
	cam_right.y = 0
	cam_right = cam_right.normalized()
	
	# Convert 2D input to 3D movement relative to camera
	return cam_forward * -input_vector.y + cam_right * input_vector.x

## Check for special input combinations
func is_crouch_pressed() -> bool:
	return Input.is_action_pressed("crouch")

## Get right stick input for camera control (gamepad)
func get_camera_input() -> Vector2:
	if device_id < 0 or not enable_gamepad:
		return Vector2.ZERO
	
	# Check if the device is still connected
	var connected_joypads = Input.get_connected_joypads()
	if not device_id in connected_joypads:
		return Vector2.ZERO
	
	var camera_input = Vector2()
	camera_input.x = Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_X)
	camera_input.y = Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_Y)
	
	# Apply deadzone
	if camera_input.length() < gamepad_deadzone:
		camera_input = Vector2.ZERO
	
	return camera_input

## Disable input processing
func disable() -> void:
	enable_gamepad = false
	enable_keyboard = false
	set_process_unhandled_input(false)

## Enable input processing
func enable() -> void:
	enable_gamepad = true
	enable_keyboard = true
	set_process_unhandled_input(true)

## Update device ID (for hot-swapping controllers)
func update_device_id(new_device_id: int) -> void:
	var old_device = device_id
	device_id = new_device_id
	# Reset button states when switching devices
	is_jump_pressed = false
	is_skill_pressed = false
	_was_jump_pressed = false
	_was_skill_pressed = false
	print("[PlayerInput] Device updated from %d to %d" % [old_device, new_device_id])