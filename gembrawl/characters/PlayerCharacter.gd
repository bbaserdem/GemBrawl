## Player3D - Main player controller using component system
## Coordinates between movement, combat, stats, and input components
class_name Player3D
extends CharacterBody3D

# Ensure dependencies are loaded and available as constants
const CombatLayers = preload("res://scripts/CombatLayers.gd")
const PlayerMovement = preload("res://characters/components/PlayerMovement.gd")
const PlayerCombat = preload("res://characters/components/PlayerCombat.gd")
const PlayerStats = preload("res://characters/components/PlayerStats.gd")
const PlayerInput = preload("res://characters/components/PlayerInput.gd")

## Player properties
@export var gem_data: Resource  # Gem resource
@export var player_id: int = 1
@export var is_local_player: bool = true

## Component references - untyped to avoid circular dependencies
@onready var movement = $Movement
@onready var combat = $Combat
@onready var stats = $Stats
@onready var input = $Input

## Visual nodes
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var direction_indicator: Node3D = $DirectionArrow

## Arena reference - untyped to avoid circular dependencies
var arena

## Quick access to state (delegated to components)
var is_alive: bool:
	get: return stats.is_alive if stats else true
var is_spectator: bool:
	get: return stats.is_spectator if stats else false
var invulnerable: bool:
	get: return combat.invulnerable if combat else false
var current_hex: Vector2i:
	get: return movement.current_hex if movement else Vector2i.ZERO

## Signals (re-exposed from components)
signal health_changed(new_health: int, max_health: int)
signal defeated()
signal skill_used()
signal hex_entered(hex_coord: Vector2i)
signal lives_changed(new_lives: int, max_lives: int)
signal became_spectator()
signal respawning(time_until_respawn: float)
signal damage_dealt(damage_info)
signal damage_received(damage_info)

func _ready() -> void:
	# Debug: Check if scene components loaded properly
	print("=== Player3D Component Loading Debug ===")
	print("movement: ", movement, " type: ", type_string(typeof(movement)) if movement else "null")
	print("combat: ", combat, " type: ", type_string(typeof(combat)) if combat else "null")
	print("stats: ", stats, " type: ", type_string(typeof(stats)) if stats else "null")
	print("input: ", input, " type: ", type_string(typeof(input)) if input else "null")
	
	if movement:
		print("movement has process_movement: ", movement.has_method("process_movement"))
		print("movement script: ", movement.get_script())
	
	# Add components if they don't exist
	_ensure_components()
	
	# Configure floor stepping
	floor_stop_on_slope = true
	floor_block_on_wall = true
	floor_snap_length = 0.3
	floor_max_angle = deg_to_rad(45)
	
	# Set up collision layers for combat
	CombatLayers.setup_combat_body(self, CombatLayers.Layer.PLAYER)
	
	# Find arena in scene
	arena = get_node_or_null("/root/Main/HexArena")
	
	# Initialize components
	_setup_components()
	
	# Apply gem properties
	_apply_gem_properties()
	
	# Add to players group for easy access
	add_to_group("players")
	
	# Connect component signals
	_connect_signals()

## Ensure all components exist
func _ensure_components() -> void:
	print("=== Ensuring Components ===")
	
	# Pass self to components (they expect IPlayer interface)
	
	if not movement:
		print("Creating new movement component")
		movement = PlayerMovement.new()
		movement.name = "Movement"
		add_child(movement)
		movement.player = self
	else:
		print("Movement component already exists from scene")
		movement.player = self
	
	if not combat:
		print("Creating new combat component")
		combat = PlayerCombat.new()
		combat.name = "Combat"
		add_child(combat)
		combat.player = self
	else:
		print("Combat component already exists from scene")
		combat.player = self
	
	if not stats:
		print("Creating new stats component")
		stats = PlayerStats.new()
		stats.name = "Stats"
		add_child(stats)
		stats.player = self
	else:
		print("Stats component already exists from scene")
		stats.player = self
	
	if not input:
		print("Creating new input component")
		input = PlayerInput.new()
		input.name = "Input"
		add_child(input)
		input.player = self
	else:
		print("Input component already exists from scene")
		input.player = self

## Public setup method for external initialization
func setup(arena_ref) -> void:
	arena = arena_ref
	# Ensure all components are initialized even if arena is null
	_setup_components()
	# Make sure stats are initialized with gem data
	if stats and gem_data and not stats.gem_data:
		stats.setup(gem_data)

## Setup components with initial data
func _setup_components() -> void:
	if movement and arena:
		movement.setup(arena)
	
	if combat and gem_data:
		combat.setup(gem_data)
	
	if stats and gem_data:
		stats.setup(gem_data)

## Apply gem properties to player
func _apply_gem_properties() -> void:
	if not gem_data:
		return
	
	# Apply movement speed
	if movement:
		movement.movement_speed = gem_data.movement_speed / 100.0  # Convert to 3D scale
	
	# Apply gem visuals
	if mesh_instance:
		# Load 3D model if specified
		if gem_data.model_path != "":
			var gem_model = load(gem_data.model_path)
			if gem_model:
				# Hide the default capsule mesh
				mesh_instance.mesh = null
				
				# Clear existing mesh children
				for child in mesh_instance.get_children():
					child.queue_free()
				
				# Instance the new model
				var instance = gem_model.instantiate()
				mesh_instance.add_child(instance)
				
				# Scale the model appropriately
				instance.scale = Vector3.ONE * 0.5  # Adjust scale as needed
				
				# Apply gem-specific material enhancements
				_apply_gem_material_enhancements(instance, gem_data)
		else:
			# Fallback to colored material if no model specified
			var material = StandardMaterial3D.new()
			material.albedo_color = gem_data.color
			mesh_instance.material_override = material

## Apply enhanced materials to gem models based on gem type
func _apply_gem_material_enhancements(node: Node, gem_data) -> void:
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		
		# Use the outlined gem shader for a nice toon-shaded look
		var shader = load("res://shaders/outlined_gem.gdshader")
		if shader:
			var shader_material = ShaderMaterial.new()
			shader_material.shader = shader
			
			# Set up gem colors based on type
			var gem_color: Color
			var highlight_color: Color
			var shadow_color: Color
			var outline_color: Color
			
			match gem_data.element:
				"ruby":
					gem_color = Color(0.9, 0.15, 0.2, 1.0)
					highlight_color = Color(1.0, 0.5, 0.6, 1.0)
					shadow_color = Color(0.4, 0.05, 0.1, 1.0)
					outline_color = Color(0.2, 0.0, 0.0, 1.0)
				"sapphire":
					gem_color = Color(0.1, 0.3, 1.0, 1.0)
					highlight_color = Color(0.5, 0.6, 1.0, 1.0)
					shadow_color = Color(0.05, 0.15, 0.4, 1.0)
					outline_color = Color(0.0, 0.1, 0.2, 1.0)
				"emerald":
					gem_color = Color(0.1, 0.8, 0.3, 1.0)
					highlight_color = Color(0.5, 1.0, 0.6, 1.0)
					shadow_color = Color(0.05, 0.4, 0.15, 1.0)
					outline_color = Color(0.0, 0.2, 0.05, 1.0)
				_:
					# Default colors
					gem_color = gem_data.color
					highlight_color = gem_data.color.lightened(0.3)
					shadow_color = gem_data.color.darkened(0.3)
					outline_color = gem_data.color.darkened(0.5)
			
			# Set shader parameters
			shader_material.set_shader_parameter("gem_color", gem_color)
			shader_material.set_shader_parameter("highlight_color", highlight_color)
			shader_material.set_shader_parameter("shadow_color", shadow_color)
			shader_material.set_shader_parameter("outline_color", outline_color)
			shader_material.set_shader_parameter("light_threshold", 0.5)
			shader_material.set_shader_parameter("shadow_threshold", 0.3)
			shader_material.set_shader_parameter("outline_width", 0.02)
			
			mesh_instance.material_override = shader_material
		else:
			# Fallback to standard material if shader not found
			var material = StandardMaterial3D.new()
			material.albedo_color = gem_data.color
			material.metallic = 0.0
			material.roughness = 0.05
			material.specular = 0.8
			mesh_instance.material_override = material
	
	# Apply to all children
	for child in node.get_children():
		_apply_gem_material_enhancements(child, gem_data)

## Connect signals from components to re-expose them
func _connect_signals() -> void:
	# Movement signals
	if movement:
		movement.hex_entered.connect(_on_hex_entered)
	
	# Combat signals
	if combat:
		combat.damage_dealt.connect(_on_damage_dealt)
		combat.damage_received.connect(_on_damage_received)
		combat.skill_used.connect(_on_skill_used)
	
	# Stats signals
	if stats:
		stats.health_changed.connect(_on_health_changed)
		stats.lives_changed.connect(_on_lives_changed)
		stats.defeated.connect(_on_defeated)
		stats.became_spectator.connect(_on_became_spectator)
		stats.respawning.connect(_on_respawning)

func _physics_process(delta: float) -> void:
	if not is_local_player:
		return
	
	# Get input
	var input_vector = input.get_movement_input() if input else Vector2.ZERO
	
	# Handle movement based on state
	if stats and stats.is_spectator:
		if movement:
			movement.handle_spectator_movement(delta, input_vector)
	elif stats and stats.is_alive:
		# Normal movement
		if movement:
			movement.process_movement(delta, input_vector)
		
		# Update combat
		if combat:
			combat.process_combat(delta)
		
		# Check for skill usage
		if input and combat and input.is_skill_action_pressed() and combat.is_skill_ready():
			use_skill()

## Public interface methods that delegate to components

## Take damage (legacy method)
func take_damage(damage: int, attacker: Node3D = null) -> void:
	if not combat or not stats:
		return
	
	var is_defeated = combat.take_damage(damage, attacker)
	if is_defeated:
		stats.handle_defeat()

## Take damage using the new damage system
func take_damage_info(damage_info) -> void:
	if not combat or not stats:
		return
	
	var is_defeated = combat.take_damage_info(damage_info)
	if is_defeated:
		stats.handle_defeat()

## Get defense value against specific damage type
func get_defense_against(damage_type) -> int:
	return combat.get_defense_against(damage_type) if combat else 0

## Get this player's element type
func get_element() -> String:
	return combat.get_element() if combat else ""

## Visual feedback for taking damage
func flash_damage() -> void:
	if not mesh_instance:
		return
	
	# Store original material
	var original_mat = mesh_instance.material_override
	
	# Create flash material
	var flash_mat = StandardMaterial3D.new()
	flash_mat.albedo_color = Color(1.0, 0.3, 0.3, 1.0)
	flash_mat.emission_enabled = true
	flash_mat.emission = Color(1.0, 0.0, 0.0)
	flash_mat.emission_energy = 2.0
	
	# Apply flash
	mesh_instance.material_override = flash_mat
	
	# Return to original after delay
	await get_tree().create_timer(0.2).timeout
	if is_instance_valid(mesh_instance):
		mesh_instance.material_override = original_mat

## Use the gem's special skill
func use_skill() -> void:
	if combat and combat.use_skill():
		pass  # Skill was used successfully

## Respawn the player at a given position
func respawn(spawn_position: Vector3) -> void:
	print("PlayerCharacter: respawn called with position ", spawn_position)
	if stats:
		stats.respawn(spawn_position)
	else:
		print("PlayerCharacter: No stats component!")

## Set position to a specific hex
func set_hex_position(hex_coord: Vector2i) -> void:
	if movement:
		movement.set_hex_position(hex_coord)

## Signal handlers to re-emit from components
func _on_hex_entered(hex_coord: Vector2i) -> void:
	hex_entered.emit(hex_coord)

func _on_damage_dealt(damage_info) -> void:
	damage_dealt.emit(damage_info)

func _on_damage_received(damage_info) -> void:
	damage_received.emit(damage_info)

func _on_skill_used() -> void:
	skill_used.emit()

func _on_health_changed(new_health: int, max_health: int) -> void:
	health_changed.emit(new_health, max_health)

func _on_lives_changed(new_lives: int, max_lives: int) -> void:
	lives_changed.emit(new_lives, max_lives)

func _on_defeated() -> void:
	defeated.emit()

func _on_became_spectator() -> void:
	became_spectator.emit()

func _on_respawning(time_until_respawn: float) -> void:
	respawning.emit(time_until_respawn)

## Additional helper methods for components
func get_arena() -> Node:
	return arena

func get_player_id() -> int:
	return player_id

func get_stats() -> Node:
	return stats

func get_combat() -> Node:
	return combat

func get_movement() -> Node:
	return movement

func get_input() -> Node:
	return input

# These methods are not needed as they duplicate built-in functionality
# Use the built-in properties directly: visible, collision_layer, collision_mask
