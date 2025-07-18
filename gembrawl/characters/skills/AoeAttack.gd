## AoE attack system for GemBrawl
## Creates area-of-effect attacks with various shapes and behaviors
class_name AoeAttack
extends Node3D

## AoE properties
@export var damage: int = 30
@export var damage_type: DamageSystem.DamageType = DamageSystem.DamageType.ELEMENTAL
@export var radius: float = 3.0
@export var delay_before_damage: float = 0.5  # Warning time before damage
@export var duration: float = 0.1  # How long the damage zone is active
@export var damage_interval: float = 0.0  # For persistent AoEs (0 = single hit)

## Visual properties
@export var warning_effect_scene: PackedScene
@export var explosion_effect_scene: PackedScene
@export var persistent_effect_scene: PackedScene

## Shape types for AoE
enum Shape {
	SPHERE,      # Standard circular AoE
	CONE,        # Cone-shaped attack
	LINE,        # Line attack
	RING         # Ring/donut shaped
}
@export var shape: Shape = Shape.SPHERE
@export var cone_angle: float = 60.0  # For cone shape
@export var line_width: float = 2.0   # For line shape
@export var ring_inner_radius: float = 1.0  # For ring shape

## Internal state
var owner_player: Player3D
var targets_hit: Array[Node3D] = []
var is_active: bool = false
var damage_timer: float = 0.0

## Signals
signal hit_targets(targets: Array[Node3D])
signal aoe_finished()

func _ready() -> void:
	# Show warning effect
	if delay_before_damage > 0:
		# Create built-in warning visual if no scene provided
		if not warning_effect_scene:
			var warning = preload("res://effects/AoeVisual.gd").new()
			add_child(warning)
			warning.setup(radius, shape, delay_before_damage)
		else:
			var warning = warning_effect_scene.instantiate()
			add_child(warning)
			_scale_effect_to_radius(warning)
	
	# Wait for delay
	if delay_before_damage > 0:
		await get_tree().create_timer(delay_before_damage).timeout
	
	# Activate damage zone
	_activate()

## Initialize the AoE attack
func setup(player: Player3D, position: Vector3, facing: Vector3 = Vector3.FORWARD) -> void:
	owner_player = player
	global_position = position
	look_at(position + facing, Vector3.UP)

## Activate the damage zone
func _activate() -> void:
	is_active = true
	
	# Show explosion effect
	if explosion_effect_scene:
		var explosion = explosion_effect_scene.instantiate()
		add_child(explosion)
		_scale_effect_to_radius(explosion)
	
	# Show persistent effect for duration-based AoEs
	if duration > damage_interval and persistent_effect_scene:
		var persistent = persistent_effect_scene.instantiate()
		add_child(persistent)
		_scale_effect_to_radius(persistent)
	
	# Single damage check
	if damage_interval <= 0:
		_check_targets()
		await get_tree().create_timer(duration).timeout
		_deactivate()
	else:
		# Persistent damage over time
		_process_persistent_damage()

## Process persistent damage
func _process_persistent_damage() -> void:
	var time_elapsed: float = 0.0
	
	while time_elapsed < duration and is_active:
		_check_targets()
		await get_tree().create_timer(damage_interval).timeout
		time_elapsed += damage_interval
		
		# Clear hit list for next tick (allows re-hitting)
		if damage_interval > 0:
			targets_hit.clear()
	
	_deactivate()

## Check and damage targets in area
func _check_targets() -> void:
	var space_state = get_world_3d().direct_space_state
	var targets_found: Array[Node3D] = []
	
	match shape:
		Shape.SPHERE:
			targets_found = _get_targets_in_sphere(space_state)
		Shape.CONE:
			targets_found = _get_targets_in_cone(space_state)
		Shape.LINE:
			targets_found = _get_targets_in_line(space_state)
		Shape.RING:
			targets_found = _get_targets_in_ring(space_state)
	
	# Apply damage to all targets
	for target in targets_found:
		if _is_valid_target(target) and target not in targets_hit:
			targets_hit.append(target)
			_apply_damage_to_target(target)
	
	if targets_hit.size() > 0:
		hit_targets.emit(targets_hit)

## Get targets in sphere
func _get_targets_in_sphere(space_state: PhysicsDirectSpaceState3D) -> Array[Node3D]:
	var shape_rid = PhysicsServer3D.sphere_shape_create()
	PhysicsServer3D.shape_set_data(shape_rid, radius)
	
	var params = PhysicsShapeQueryParameters3D.new()
	params.shape_rid = shape_rid
	params.transform = global_transform
	params.collision_mask = CombatLayers.get_layer_bit(CombatLayers.Layer.PLAYER) | \
						   CombatLayers.get_layer_bit(CombatLayers.Layer.ENEMY)
	
	var results = space_state.intersect_shape(params, 32)
	PhysicsServer3D.free_rid(shape_rid)
	
	var targets: Array[Node3D] = []
	for result in results:
		if result.collider:
			targets.append(result.collider)
	return targets

## Get targets in cone
func _get_targets_in_cone(space_state: PhysicsDirectSpaceState3D) -> Array[Node3D]:
	# First get all targets in sphere
	var potential_targets = _get_targets_in_sphere(space_state)
	var targets: Array[Node3D] = []
	
	var forward = -global_transform.basis.z
	var half_angle = deg_to_rad(cone_angle * 0.5)
	
	for target in potential_targets:
		var to_target = (target.global_position - global_position).normalized()
		var angle = forward.angle_to(to_target)
		
		if angle <= half_angle:
			targets.append(target)
	
	return targets

## Get targets in line
func _get_targets_in_line(space_state: PhysicsDirectSpaceState3D) -> Array[Node3D]:
	var shape_rid = PhysicsServer3D.box_shape_create()
	var box_size = Vector3(line_width, 2.0, radius)  # Width x Height x Length
	PhysicsServer3D.shape_set_data(shape_rid, box_size)
	
	var params = PhysicsShapeQueryParameters3D.new()
	params.shape_rid = shape_rid
	params.transform = global_transform
	params.collision_mask = CombatLayers.get_layer_bit(CombatLayers.Layer.PLAYER) | \
						   CombatLayers.get_layer_bit(CombatLayers.Layer.ENEMY)
	
	var results = space_state.intersect_shape(params, 32)
	PhysicsServer3D.free_rid(shape_rid)
	
	var targets: Array[Node3D] = []
	for result in results:
		if result.collider:
			targets.append(result.collider)
	return targets

## Get targets in ring
func _get_targets_in_ring(space_state: PhysicsDirectSpaceState3D) -> Array[Node3D]:
	# Get all targets in outer sphere
	var outer_targets = _get_targets_in_sphere(space_state)
	var targets: Array[Node3D] = []
	
	# Filter out targets in inner sphere
	for target in outer_targets:
		var distance = global_position.distance_to(target.global_position)
		if distance >= ring_inner_radius:
			targets.append(target)
	
	return targets

## Check if target is valid
func _is_valid_target(target: Node3D) -> bool:
	# Don't hit self
	if target == owner_player:
		return false
	
	# Must have damage reception
	if not target.has_method("take_damage_info"):
		return false
	
	# Must be alive
	if target.has_method("is_alive") and not target.is_alive:
		return false
	
	return true

## Apply damage to target
func _apply_damage_to_target(target: Node3D) -> void:
	var damage_info = DamageSystem.create_skill_damage(
		owner_player,
		target,
		damage,
		"AoE Attack",
		damage_type
	)
	
	# AoE attacks often have reduced damage at edges
	var distance = global_position.distance_to(target.global_position)
	var falloff = 1.0 - (distance / radius) * 0.3  # Up to 30% damage reduction at edge
	damage_info.multiplier = max(0.7, falloff)
	
	target.take_damage_info(damage_info)

## Scale effect to match radius
func _scale_effect_to_radius(effect: Node3D) -> void:
	if shape == Shape.SPHERE or shape == Shape.RING:
		effect.scale = Vector3.ONE * (radius * 2.0)
	elif shape == Shape.CONE:
		effect.scale.z = radius
		effect.scale.x = tan(deg_to_rad(cone_angle * 0.5)) * radius * 2.0
	elif shape == Shape.LINE:
		effect.scale.x = line_width
		effect.scale.z = radius

## Deactivate the AoE
func _deactivate() -> void:
	is_active = false
	aoe_finished.emit()
	queue_free()

## Create an AoE attack
static func create_aoe(scene: PackedScene, owner: Player3D, 
		position: Vector3, facing: Vector3 = Vector3.FORWARD) -> AoeAttack:
	var aoe = scene.instantiate() as AoeAttack
	# Get the current scene to add AoE to
	var current_scene = owner.get_tree().current_scene
	if current_scene:
		current_scene.add_child(aoe)
	else:
		owner.get_parent().add_child(aoe)
	aoe.setup(owner, position, facing)
	return aoe 