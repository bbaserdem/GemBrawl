## HazardTile - Environmental hazard that damages players
## Handles spike and lava tile damage mechanics
class_name HazardTile
extends Area3D

# Ensure dependencies are loaded and available as constants
const DamageSystem = preload("res://scripts/DamageSystem.gd")
const CombatLayers = preload("res://scripts/CombatLayers.gd")

## Hazard types
enum HazardType {
	SPIKE,
	LAVA
}

## Hazard configuration
@export var hazard_type: HazardType = HazardType.LAVA
@export var damage_amount: int = 10
@export var damage_interval: float = 1.0  # Time between damage ticks
@export var spike_trigger_delay: float = 0.5  # Delay before spikes activate

## Visual settings
@export var lava_material: StandardMaterial3D
@export var spike_material: StandardMaterial3D
@export var spike_height: float = 0.8  # Height when extended

## Internal state
var players_in_hazard: Dictionary = {}  # Player -> last_damage_time
var spike_triggered: bool = false
var spike_animation_time: float = 0.0

## References
var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D
var spike_mesh: MeshInstance3D  # For spike animation

func _ready() -> void:
	# Connect area signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Set up collision layers
	collision_layer = 0  # Hazards don't need to be on any layer
	collision_mask = CombatLayers.PLAYER_MASK  # Only detect players
	
	# Setup visuals based on type
	_setup_hazard_visuals()

## Setup visual elements based on hazard type
func _setup_hazard_visuals() -> void:
	# Get or create mesh instance
	mesh_instance = get_node_or_null("MeshInstance3D")
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		add_child(mesh_instance)
	
	match hazard_type:
		HazardType.LAVA:
			_setup_lava_visuals()
		HazardType.SPIKE:
			_setup_spike_visuals()

## Setup lava tile visuals
func _setup_lava_visuals() -> void:
	if lava_material:
		mesh_instance.material_override = lava_material
	else:
		# Create default lava material
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.3, 0.0)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.5, 0.0)
		mat.emission_energy = 1.0
		mat.roughness = 0.2
		mesh_instance.material_override = mat

## Setup spike tile visuals
func _setup_spike_visuals() -> void:
	# Create spike mesh for animation
	spike_mesh = MeshInstance3D.new()
	add_child(spike_mesh)
	
	# Create spike geometry (simple pyramid for now)
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	
	# Spike points (4 spikes in a pattern)
	var spike_positions = [
		Vector3(0.3, 0, 0.3),
		Vector3(-0.3, 0, 0.3),
		Vector3(0.3, 0, -0.3),
		Vector3(-0.3, 0, -0.3)
	]
	
	for spike_pos in spike_positions:
		# Each spike is a pyramid
		var tip = spike_pos + Vector3(0, spike_height, 0)
		var base_size = 0.15
		
		# Add pyramid faces
		_add_pyramid_to_arrays(spike_pos, tip, base_size, vertices, normals, uvs)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	
	var spike_array_mesh = ArrayMesh.new()
	spike_array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	spike_mesh.mesh = spike_array_mesh
	
	# Apply material
	if spike_material:
		spike_mesh.material_override = spike_material
	else:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.6, 0.6, 0.7)
		mat.metallic = 0.8
		mat.roughness = 0.3
		spike_mesh.material_override = mat
	
	# Start with spikes retracted
	spike_mesh.position.y = -spike_height

## Add pyramid geometry to arrays
func _add_pyramid_to_arrays(base_pos: Vector3, tip: Vector3, size: float, 
		vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array) -> void:
	# Base vertices
	var v1 = base_pos + Vector3(-size, 0, -size)
	var v2 = base_pos + Vector3(size, 0, -size)
	var v3 = base_pos + Vector3(size, 0, size)
	var v4 = base_pos + Vector3(-size, 0, size)
	
	# Front face
	vertices.append_array([v1, v2, tip])
	var n1 = ((v2 - v1).cross(tip - v1)).normalized()
	normals.append_array([n1, n1, n1])
	uvs.append_array([Vector2(0, 1), Vector2(1, 1), Vector2(0.5, 0)])
	
	# Right face
	vertices.append_array([v2, v3, tip])
	var n2 = ((v3 - v2).cross(tip - v2)).normalized()
	normals.append_array([n2, n2, n2])
	uvs.append_array([Vector2(0, 1), Vector2(1, 1), Vector2(0.5, 0)])
	
	# Back face
	vertices.append_array([v3, v4, tip])
	var n3 = ((v4 - v3).cross(tip - v3)).normalized()
	normals.append_array([n3, n3, n3])
	uvs.append_array([Vector2(0, 1), Vector2(1, 1), Vector2(0.5, 0)])
	
	# Left face
	vertices.append_array([v4, v1, tip])
	var n4 = ((v1 - v4).cross(tip - v4)).normalized()
	normals.append_array([n4, n4, n4])
	uvs.append_array([Vector2(0, 1), Vector2(1, 1), Vector2(0.5, 0)])

func _physics_process(delta: float) -> void:
	# Handle spike animation
	if hazard_type == HazardType.SPIKE and spike_mesh:
		if spike_triggered:
			# Animate spikes extending
			spike_animation_time = min(spike_animation_time + delta * 4.0, 1.0)
			spike_mesh.position.y = lerp(-spike_height, 0.0, spike_animation_time)
		else:
			# Animate spikes retracting
			spike_animation_time = max(spike_animation_time - delta * 2.0, 0.0)
			spike_mesh.position.y = lerp(-spike_height, 0.0, spike_animation_time)
	
	# Check for damage timing
	var current_time = Time.get_ticks_msec() / 1000.0
	for player in players_in_hazard:
		if is_instance_valid(player):
			var last_damage = players_in_hazard[player]
			if current_time - last_damage >= damage_interval:
				_apply_hazard_damage(player)
				players_in_hazard[player] = current_time
		else:
			# Remove invalid player references
			players_in_hazard.erase(player)

## Handle body entering hazard
func _on_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage"):
		var current_time = Time.get_ticks_msec() / 1000.0
		
		match hazard_type:
			HazardType.LAVA:
				# Immediate damage for lava
				players_in_hazard[body] = current_time
				_apply_hazard_damage(body)
			HazardType.SPIKE:
				# Delayed activation for spikes
				if not spike_triggered:
					spike_triggered = true
					await get_tree().create_timer(spike_trigger_delay).timeout
					if body in players_in_hazard:
						_apply_hazard_damage(body)
				players_in_hazard[body] = current_time

## Handle body exiting hazard
func _on_body_exited(body: Node3D) -> void:
	players_in_hazard.erase(body)
	
	# Reset spikes if no players remain
	if hazard_type == HazardType.SPIKE and players_in_hazard.is_empty():
		spike_triggered = false

## Apply damage to a player
func _apply_hazard_damage(player: Node3D) -> void:
	if not is_instance_valid(player) or not player.has_method("take_damage"):
		return
	
	# Create damage info
	var damage_info = DamageSystem.DamageInfo.new()
	damage_info.source = self
	damage_info.target = player
	damage_info.base_damage = damage_amount
	damage_info.damage_type = DamageSystem.DamageType.TRUE  # Environmental damage ignores defense
	damage_info.skill_name = "Environmental Hazard"
	
	# Apply damage
	DamageSystem.apply_damage(damage_info)
	
	# Visual feedback
	if player.has_method("flash_damage"):
		player.flash_damage()
	
	# Apply knockback for spikes
	if hazard_type == HazardType.SPIKE and player is CharacterBody3D:
		var knockback_dir = (player.global_position - global_position).normalized()
		knockback_dir.y = 0.5  # Add upward component
		player.velocity += knockback_dir * 5.0