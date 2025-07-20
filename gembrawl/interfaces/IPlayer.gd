class_name IPlayer
extends Node

# Position and movement
func get_global_position() -> Vector3:
	return Vector3.ZERO

func set_global_position(position: Vector3) -> void:
	pass

func get_velocity() -> Vector3:
	return Vector3.ZERO

func set_velocity(velocity: Vector3) -> void:
	pass

func move_and_slide() -> void:
	pass

# Rotation
func get_rotation() -> Vector3:
	return Vector3.ZERO

func set_rotation(rotation: Vector3) -> void:
	pass

# Physics
func is_on_floor() -> bool:
	return false

# Viewport
func get_viewport() -> Viewport:
	return null

# Component access
func get_stats() -> Node:
	return null

func get_combat() -> Node:
	return null

func get_arena() -> Node:
	return null

func get_movement() -> Node:
	return null

func get_input() -> Node:
	return null

# Combat methods
func take_damage(amount: int, source: Node) -> void:
	pass

func take_damage_info(damage_info) -> void:
	pass

func get_defense_against(damage_type) -> int:
	return 0

func get_element() -> String:
	return ""

func flash_damage() -> void:
	pass

# Player state
func is_alive() -> bool:
	return true

func is_spectator() -> bool:
	return false

# Arena interaction
func set_hex_position(hex_coord: Vector2i) -> void:
	pass

# Properties
func get_player_id() -> int:
	return 1

func is_local_player() -> bool:
	return true

# Node operations
func get_node_or_null(path: String) -> Node:
	return null

func get_tree() -> SceneTree:
	return null

func get_viewport() -> Viewport:
	return null

# Visibility and physics
func set_visible(visible: bool) -> void:
	pass

func set_physics_process(enable: bool) -> void:
	pass

func get_collision_layer() -> int:
	return 0

func set_collision_layer(layer: int) -> void:
	pass

func get_collision_mask() -> int:
	return 0

func set_collision_mask(mask: int) -> void:
	pass