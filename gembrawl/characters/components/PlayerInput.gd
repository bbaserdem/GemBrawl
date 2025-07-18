## PlayerInput - Handles all player input processing
## Manages keyboard, gamepad, and action inputs
class_name PlayerInput
extends Node

## Input settings
@export var gamepad_deadzone: float = 0.15
@export var enable_gamepad: bool = true
@export var enable_keyboard: bool = true

## References
var player: Player3D

## Cached input state
var current_movement_input: Vector2 = Vector2.ZERO
var is_jump_pressed: bool = false
var is_skill_pressed: bool = false

func _ready() -> void:
	player = get_parent() as Player3D
	if not player:
		push_error("PlayerInput must be a child of Player3D")
		queue_free()
	
	set_process_unhandled_input(true)

## Get movement input from player
func get_movement_input() -> Vector2:
	var input_vector = Vector2.ZERO
	
	# Gamepad input
	if enable_gamepad and Input.get_connected_joypads().size() > 0:
		input_vector.x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
		input_vector.y = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
		
		# Apply deadzone
		if input_vector.length() < gamepad_deadzone:
			input_vector = Vector2.ZERO
	
	# Keyboard input (override gamepad if pressed)
	if enable_keyboard:
		var keyboard_vector = Vector2.ZERO
		keyboard_vector.x = Input.get_axis("move_left", "move_right")
		keyboard_vector.y = Input.get_axis("move_up", "move_down")
		
		if keyboard_vector.length() > 0:
			input_vector = keyboard_vector
	
	# Normalize
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()
	
	current_movement_input = input_vector
	return input_vector

## Check if jump action is pressed
func is_jump_action_pressed() -> bool:
	return Input.is_action_just_pressed("jump")

## Check if skill action is pressed
func is_skill_action_pressed() -> bool:
	return Input.is_action_just_pressed("use_skill")

## Handle unhandled input events
func _unhandled_input(event: InputEvent) -> void:
	if not player.is_local_player:
		return
	
	# Cache action states for use in process functions
	if event.is_action_pressed("jump"):
		is_jump_pressed = true
	elif event.is_action_released("jump"):
		is_jump_pressed = false
	
	if event.is_action_pressed("use_skill"):
		is_skill_pressed = true
	elif event.is_action_released("use_skill"):
		is_skill_pressed = false

## Get camera-relative movement direction
func get_camera_relative_movement(input_vector: Vector2) -> Vector3:
	if input_vector.length() == 0:
		return Vector3.ZERO
	
	var camera = player.get_viewport().get_camera_3d()
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
	if not enable_gamepad or Input.get_connected_joypads().size() == 0:
		return Vector2.ZERO
	
	var camera_input = Vector2()
	camera_input.x = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	camera_input.y = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	
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