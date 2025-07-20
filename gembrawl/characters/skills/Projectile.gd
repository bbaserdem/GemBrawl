## Projectile system for GemBrawl
## Base class for all projectiles in the game
class_name Projectile
extends CharacterBody3D

# Import dependencies
const CombatLayers = preload("res://scripts/CombatLayers.gd")
const DamageSystem = preload("res://scripts/DamageSystem.gd")

## Projectile properties
@export var speed: float = 800.0
@export var damage: int = 15
@export var damage_type: int = 0  ## DamageSystem.DamageType (0=PHYSICAL, 1=MAGICAL, 2=TRUE, 3=ELEMENTAL)
@export var lifetime: float = 3.0
@export var pierce_count: int = 0  # How many targets it can hit before destroying
@export var homing_strength: float = 0.0  # 0 = no homing, 1 = strong homing

## Visual and physics
@export var hit_effect_scene: PackedScene
@export var trail_effect_scene: PackedScene
@export var gravity_scale: float = 0.0  # For arcing projectiles

## Internal state
var owner_player  ## IPlayer
var direction: Vector3
var targets_hit: Array[Node3D] = []
var current_pierce_count: int = 0
var homing_target: Node3D
var lifetime_timer: SceneTreeTimer  # Store timer reference for cleanup

## Components
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var hitbox: Area3D = $Hitbox

## Signals
signal hit_target(target: Node3D, damage_info: Dictionary)  ## damage_info is DamageSystem.DamageInfo
signal hit_world(position: Vector3)

func _ready() -> void:
	# Configure collision layers
	CombatLayers.setup_combat_body(self, CombatLayers.Layer.PROJECTILE)
	
	# Enable continuous collision detection for fast-moving projectiles
	set_motion_mode(CharacterBody3D.MOTION_MODE_FLOATING)
	
	# Setup hitbox if present
	if hitbox:
		CombatLayers.setup_combat_area(hitbox, CombatLayers.Layer.PROJECTILE)
		hitbox.body_entered.connect(_on_hitbox_body_entered)
		hitbox.area_entered.connect(_on_hitbox_area_entered)
		# Ensure hitbox is properly configured
		hitbox.monitoring = true
		hitbox.monitorable = false
	
	# Create trail effect
	if trail_effect_scene:
		var trail = trail_effect_scene.instantiate()
		add_child(trail)
	
	# Auto-destroy after lifetime
	lifetime_timer = get_tree().create_timer(lifetime)
	lifetime_timer.timeout.connect(_destroy)

## Initialize the projectile
## Sets owner, spawn position, and initial direction
## @param player: The player who fired this projectile
## @param spawn_position: World position to spawn at
## @param fire_direction: Initial direction vector (will be normalized)
func setup(player, spawn_position: Vector3, fire_direction: Vector3) -> void:  ## player: IPlayer
	owner_player = player
	global_position = spawn_position
	direction = fire_direction.normalized()
	
	# Face the direction of travel
	look_at(global_position + direction, Vector3.UP)

## Set a homing target
func set_homing_target(target: Node3D) -> void:
	homing_target = target

func _physics_process(delta: float) -> void:
	# Store previous position for raycast
	var prev_position = global_position
	
	# Apply homing if enabled
	if homing_strength > 0 and is_instance_valid(homing_target):
		var to_target = (homing_target.global_position - global_position).normalized()
		direction = direction.lerp(to_target, homing_strength * delta).normalized()
		look_at(global_position + direction, Vector3.UP)
	
	# Apply movement
	velocity = direction * speed
	
	# Apply gravity if enabled
	if gravity_scale > 0:
		velocity.y -= gravity_scale * 9.8 * delta
		direction = velocity.normalized()
	
	# Move and check for collisions
	move_and_slide()
	
	# Backup collision detection using raycast
	_check_raycast_collision(prev_position, global_position)
	
	# Check if hit world geometry
	if is_on_wall() or is_on_floor() or is_on_ceiling():
		_on_hit_world()

## Handle hitbox collision with bodies
## Applies damage to valid targets and manages pierce mechanics
## Ignores owner and already-hit targets based on pierce settings
## @param body: The colliding body
func _on_hitbox_body_entered(body: Node3D) -> void:
	# Don't hit the owner
	if body == owner_player:
		return
	
	# Check if body can take damage
	if body.has_method("take_damage_info"):
		var damage_info = DamageSystem.create_basic_attack(owner_player, body, damage)
		damage_info.damage_type = damage_type
		body.take_damage_info(damage_info)
		
		# Emit hit signal with damage_info as dictionary
		var damage_dict = {
			"base_damage": damage_info.base_damage,
			"damage_type": damage_info.damage_type,
			"is_critical": damage_info.is_critical,
			"final_damage": damage_info.final_damage,
			"damage_dealt": damage_info.damage_dealt,
			"skill_name": damage_info.skill_name
		}
		hit_target.emit(body, damage_dict)
		
		# Destroy projectile
		queue_free()

## Handle hitbox collision with areas
func _on_hitbox_area_entered(area: Area3D) -> void:
	# Could be used for shields, projectile deflection, etc.
	pass

## Backup collision detection using raycast
func _check_raycast_collision(from: Vector3, to: Vector3) -> void:
	# Skip if already hit something
	if targets_hit.size() > 0 and pierce_count == 0:
		return
		
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	
	# Set collision mask to match hitbox mask
	query.collision_mask = hitbox.collision_mask if hitbox else 11
	query.exclude = [self, owner_player] # Exclude self and owner
	query.collide_with_bodies = true
	query.collide_with_areas = false
	
	var result = space_state.intersect_ray(query)
	if result and result.collider:
		var body = result.collider
		# Check if it's a valid target we haven't hit yet
		if body != owner_player and body not in targets_hit and body.has_method("take_damage_info"):
			_on_hitbox_body_entered(body)

## Apply damage to target
func _apply_damage_to_target(target: Node3D) -> void:
	# Mark as hit
	targets_hit.append(target)
	
	# Create damage info
	var damage_info = DamageSystem.create_skill_damage(
		owner_player, 
		target, 
		damage,
		"Projectile",
		damage_type
	)
	
	# Apply damage
	target.take_damage_info(damage_info)
	
	# Emit signal with damage_info as dictionary
	var damage_dict = {
		"base_damage": damage_info.base_damage,
		"damage_type": damage_info.damage_type,
		"is_critical": damage_info.is_critical,
		"final_damage": damage_info.final_damage,
		"damage_dealt": damage_info.damage_dealt,
		"skill_name": damage_info.skill_name
	}
	hit_target.emit(target, damage_dict)
	
	# Create hit effect
	if hit_effect_scene:
		var effect = hit_effect_scene.instantiate()
		get_tree().current_scene.add_child(effect)
		effect.global_position = global_position

## Handle hitting world geometry
func _on_hit_world() -> void:
	hit_world.emit(global_position)
	_destroy()

## Destroy the projectile
func _destroy() -> void:
	# Create destruction effect
	if hit_effect_scene:
		var effect = hit_effect_scene.instantiate()
		get_tree().current_scene.add_child(effect)
		effect.global_position = global_position
	
	# Remove projectile
	queue_free()

## Create a projectile from a skill
static func create_projectile(scene: PackedScene, owner,  ## owner: IPlayer
		spawn_pos: Vector3, direction: Vector3) -> Projectile:
	var projectile = scene.instantiate() as Projectile
	# Get the current scene to add projectile to
	var current_scene = owner.get_tree().current_scene
	if current_scene:
		current_scene.add_child(projectile)
	else:
		owner.get_parent().add_child(projectile)
	projectile.setup(owner, spawn_pos, direction)
	return projectile 