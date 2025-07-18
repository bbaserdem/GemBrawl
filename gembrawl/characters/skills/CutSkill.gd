## Cut skill implementation for GemBrawl
## A piercing dash that damages enemies in a line
## Updated for 3D gameplay
class_name CutSkill
extends Skill

## Cut-specific properties
@export var dash_distance: float = 200.0
@export var dash_speed: float = 800.0
@export var slash_width: float = 40.0

## Raycast for collision detection
var raycast: RayCast3D

func _ready() -> void:
	skill_name = "Cut"
	description = "Dash forward with a piercing slash, damaging all enemies in your path"
	cooldown = 4.0
	damage = 30
	range = dash_distance
	
	# Create raycast for detecting enemies in path
	raycast = RayCast3D.new()
	add_child(raycast)
	raycast.enabled = false

## Perform the cut dash
func _perform_skill() -> void:
	if not owner_player:
		return
	
	# Get dash direction based on player's facing or input
	var dash_direction: Vector3 = -owner_player.transform.basis.z
	if owner_player.velocity.length() > 0:
		dash_direction = owner_player.velocity.normalized()
		dash_direction.y = 0  # Keep horizontal
	
	# Calculate target position
	var start_position: Vector3 = owner_player.global_position
	var target_position: Vector3 = start_position + (dash_direction * dash_distance)
	
	# Check for obstacles
	raycast.global_position = start_position
	raycast.position = Vector3.ZERO
	raycast.target_position = dash_direction * dash_distance
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		target_position = raycast.get_collision_point()
	
	# Store original physics state
	var original_collision_layer: int = owner_player.collision_layer
	owner_player.collision_layer = 0  # Disable collisions during dash
	
	# Perform the dash
	var dash_time: float = dash_distance / dash_speed
	var tween: Tween = create_tween()
	tween.tween_property(owner_player, "global_position", target_position, dash_time)
	
	# Check for enemies along the path
	var space_state: PhysicsDirectSpaceState3D = owner_player.get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		start_position,
		target_position,
		0b0010  # Enemy collision layer
	)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	# Damage all enemies in path
	var enemies_hit: Array[Node3D] = []
	var dash_timer: float = 0.0
	
	while dash_timer < dash_time:
		var current_pos: Vector3 = owner_player.global_position
		var check_end: Vector3 = current_pos + (dash_direction * 50)
		
		query.from = current_pos
		query.to = check_end
		
		var result: Dictionary = space_state.intersect_ray(query)
		if result and result.collider and result.collider not in enemies_hit:
			if result.collider.has_method("take_damage"):
				apply_damage_to_target(result.collider, 1.2)  # 20% bonus damage
				enemies_hit.append(result.collider)
				create_effect(result.position)
		
		dash_timer += get_process_delta_time()
		await get_tree().process_frame
	
	# Restore collision
	owner_player.collision_layer = original_collision_layer
	
	# Create slash effect along the path
	_create_slash_effect(start_position, owner_player.global_position)

## Create visual effect for the slash
func _create_slash_effect(start_pos: Vector3, end_pos: Vector3) -> void:
	# This would create a line particle effect or animated sprite
	# For now, just use the base effect system
	create_effect(start_pos)
	create_effect(end_pos)