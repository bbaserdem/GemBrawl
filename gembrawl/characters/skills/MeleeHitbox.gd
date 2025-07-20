## Melee hitbox component for GemBrawl
## Attach to an Area3D node to create a melee attack hitbox
class_name MeleeHitbox
extends Area3D

# Import dependencies
const CombatLayers = preload("res://scripts/CombatLayers.gd")
const DamageSystem = preload("res://scripts/DamageSystem.gd")

## Hitbox properties
@export var damage: int = 10
@export var damage_type: int = 0  ## DamageSystem.DamageType (0=PHYSICAL, 1=MAGICAL, 2=TRUE, 3=ELEMENTAL)
@export var knockback_force: float = 300.0
@export var active_time: float = 0.2  # How long the hitbox stays active
@export var hit_pause_duration: float = 0.05  # Brief pause on hit for impact feel

## Internal state
var owner_player  ## IPlayer interface - injected from parent
var targets_hit: Array[Node3D] = []  # Prevent hitting same target multiple times
var is_active: bool = false
var deactivate_timer: SceneTreeTimer  # Store timer reference

## Signals
signal hit_target(target: Node3D, damage_info: Dictionary)  ## damage_info is DamageSystem.DamageInfo

func _ready() -> void:
	# Configure collision layers
	CombatLayers.setup_combat_area(self, CombatLayers.Layer.PLAYER_HITBOX)
	
	# Connect area signals
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Start disabled
	monitoring = false
	monitorable = false

## Initialize the hitbox with its owner
func setup(player) -> void:  ## player: IPlayer interface
	owner_player = player

## Activate the hitbox for an attack
func activate(custom_damage: int = -1, custom_duration: float = -1) -> void:
	if is_active:
		return
	
	# Reset state
	is_active = true
	targets_hit.clear()
	
	# Apply custom values if provided
	if custom_damage > 0:
		damage = custom_damage
	if custom_duration > 0:
		active_time = custom_duration
	
	# Enable collision detection
	monitoring = true
	monitorable = true
	visible = true  # Optional: show debug visualization
	
	# Auto-deactivate after duration
	deactivate_timer = get_tree().create_timer(active_time)
	deactivate_timer.timeout.connect(deactivate)

## Deactivate the hitbox
func deactivate() -> void:
	is_active = false
	monitoring = false
	monitorable = false
	visible = false
	targets_hit.clear()

## Handle body collision
func _on_body_entered(body: Node3D) -> void:
	if not is_active:
		return
	
	if not _is_valid_target(body):
		return
	
	# Check if already hit
	if body in targets_hit:
		return
	
	# Mark as hit
	targets_hit.append(body)
	
	# Apply damage
	_apply_damage_to_target(body)
	
	# Apply knockback
	_apply_knockback(body)
	
	# Hit pause for impact feel
	if hit_pause_duration > 0:
		_apply_hit_pause()

## Handle area collision (for special defenses)
func _on_area_entered(area: Area3D) -> void:
	# Could be used for shields, counters, etc.
	pass

## Check if target is valid
func _is_valid_target(target: Node3D) -> bool:
	# Don't hit self
	if target == owner_player:
		return false
	
	# Must have damage reception method
	if not target.has_method("take_damage_info"):
		return false
	
	# Must be alive (if applicable)
	if target.has_method("is_alive") and not target.is_alive:
		return false
	
	return true

## Apply damage to target
func _apply_damage_to_target(target: Node3D) -> void:
	# Create damage info
	var damage_info = DamageSystem.create_basic_attack(owner_player, target, damage)
	damage_info.damage_type = damage_type
	
	# Apply through damage system
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

## Apply knockback to target
func _apply_knockback(target: Node3D) -> void:
	if knockback_force <= 0:
		return
	
	# Calculate knockback direction
	var knockback_dir = (target.global_position - global_position).normalized()
	knockback_dir.y = 0  # Keep it horizontal
	
	# Apply knockback if target has velocity
	if "velocity" in target:
		target.velocity += knockback_dir * knockback_force

## Apply hit pause effect
func _apply_hit_pause() -> void:
	# Brief time slowdown on hit
	Engine.time_scale = 0.3
	await get_tree().create_timer(hit_pause_duration * 0.3).timeout
	Engine.time_scale = 1.0

## Get current damage value (for UI/debugging)
func get_damage() -> int:
	if owner_player and owner_player.gem_data:
		return damage + owner_player.gem_data.base_damage
	return damage 