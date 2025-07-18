## Camera controller for combat test scenes
## Follows the active player and supports gamepad zoom
extends Camera3D

## Camera settings
@export var follow_distance: float = 10.0
@export var follow_height: float = 10.0
@export var look_at_offset: Vector3 = Vector3(0, 1, 0)
@export var follow_speed: float = 5.0
@export var zoom_speed: float = 2.0
@export var min_distance: float = 5.0
@export var max_distance: float = 20.0

## Target to follow
var target: Node3D
var current_distance: float

func _ready() -> void:
	current_distance = follow_distance
	# Find initial player to follow
	_find_player_to_follow()

func _find_player_to_follow() -> void:
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if "is_local_player" in player and player.is_local_player:
			target = player
			break

func _process(delta: float) -> void:
	# Update target if needed
	if not is_instance_valid(target):
		_find_player_to_follow()
		return
	
	if not target:
		return
	
	# Handle zoom input
	_handle_zoom(delta)
	
	# Calculate desired position
	var target_pos = target.global_position
	var desired_position = target_pos + Vector3(0, follow_height, current_distance)
	
	# Smoothly move to desired position
	global_position = global_position.lerp(desired_position, follow_speed * delta)
	
	# Look at target
	look_at(target_pos + look_at_offset, Vector3.UP)

func _handle_zoom(delta: float) -> void:
	var zoom_input = 0.0
	
	# Gamepad right stick Y-axis
	var gamepad_zoom = Input.get_axis("camera_zoom_in", "camera_zoom_out")
	zoom_input = gamepad_zoom
	
	# Mouse wheel support
	if Input.is_action_pressed("camera_zoom_in"):
		zoom_input = -1.0
	elif Input.is_action_pressed("camera_zoom_out"):
		zoom_input = 1.0
	
	# Apply zoom
	if abs(zoom_input) > 0.1:
		current_distance += zoom_input * zoom_speed * delta
		current_distance = clamp(current_distance, min_distance, max_distance)
		follow_height = current_distance * 0.7  # Adjust height based on distance

## Set a new target to follow
func set_target(new_target: Node3D) -> void:
	target = new_target 
