## Simple camera controller for testing
## Follows target without interfering with player input
class_name SimpleCameraController
extends Node3D

@export var follow_target: Node3D
@export var follow_distance: float = 20.0
@export var follow_height: float = 15.0
@export var follow_smoothness: float = 5.0

func _ready() -> void:
	# Find player if not set
	if not follow_target:
		follow_target = get_node_or_null("../Player")

func _process(delta: float) -> void:
	if not follow_target:
		return
	
	# Calculate target position
	var target_pos = follow_target.global_position
	target_pos.y = follow_target.global_position.y + follow_height
	target_pos.z += follow_distance * 0.5  # Offset backwards
	
	# Smoothly follow
	global_position = global_position.lerp(target_pos, follow_smoothness * delta)
	
	# Look at player
	look_at(follow_target.global_position, Vector3.UP) 