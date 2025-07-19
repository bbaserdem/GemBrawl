## Player3D - Main player controller using component system
## Coordinates between movement, combat, stats, and input components
class_name Player3D
extends CharacterBody3D

## Player properties
@export var gem_data: Gem
@export var player_id: int = 1
@export var is_local_player: bool = true

## Component references
@onready var movement: PlayerMovement = $Movement
@onready var combat: PlayerCombat = $Combat
@onready var stats: PlayerStats = $Stats
@onready var input: PlayerInput = $Input

## Visual nodes
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var direction_indicator: Node3D = $DirectionArrow

## Arena reference
var arena: HexArena

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
signal damage_dealt(damage_info: DamageSystem.DamageInfo)
signal damage_received(damage_info: DamageSystem.DamageInfo)

func _ready() -> void:
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
	if not movement:
		movement = PlayerMovement.new()
		movement.name = "Movement"
		add_child(movement)
	
	if not combat:
		combat = PlayerCombat.new()
		combat.name = "Combat"
		add_child(combat)
	
	if not stats:
		stats = PlayerStats.new()
		stats.name = "Stats"
		add_child(stats)
	
	if not input:
		input = PlayerInput.new()
		input.name = "Input"
		add_child(input)

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
				# Clear existing mesh
				for child in mesh_instance.get_children():
					child.queue_free()
				
				# Instance the new model
				var instance = gem_model.instantiate()
				mesh_instance.add_child(instance)
				
				# Scale the model appropriately
				instance.scale = Vector3.ONE * 0.5  # Adjust scale as needed
		else:
			# Fallback to colored material if no model specified
			var material = StandardMaterial3D.new()
			material.albedo_color = gem_data.color
			mesh_instance.material_override = material

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
func take_damage_info(damage_info: DamageSystem.DamageInfo) -> void:
	if not combat or not stats:
		return
	
	var is_defeated = combat.take_damage_info(damage_info)
	if is_defeated:
		stats.handle_defeat()

## Get defense value against specific damage type
func get_defense_against(damage_type: DamageSystem.DamageType) -> int:
	return combat.get_defense_against(damage_type) if combat else 0

## Get this player's element type
func get_element() -> String:
	return combat.get_element() if combat else ""

## Use the gem's special skill
func use_skill() -> void:
	if combat and combat.use_skill():
		pass  # Skill was used successfully

## Respawn the player at a given position
func respawn(spawn_position: Vector3) -> void:
	if stats:
		stats.respawn(spawn_position)

## Set position to a specific hex
func set_hex_position(hex_coord: Vector2i) -> void:
	if movement:
		movement.set_hex_position(hex_coord)

## Signal handlers to re-emit from components
func _on_hex_entered(hex_coord: Vector2i) -> void:
	hex_entered.emit(hex_coord)

func _on_damage_dealt(damage_info: DamageSystem.DamageInfo) -> void:
	damage_dealt.emit(damage_info)

func _on_damage_received(damage_info: DamageSystem.DamageInfo) -> void:
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
