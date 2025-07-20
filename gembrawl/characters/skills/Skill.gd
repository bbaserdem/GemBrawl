## Base skill class for all gem abilities in GemBrawl
## Provides common interface and functionality for skills
class_name Skill
extends Node

# Import dependencies
const DamageSystem = preload("res://scripts/DamageSystem.gd")

## Skill properties
@export var skill_name: String = "Basic Skill"
@export var description: String = ""
@export var icon: Texture2D

## Skill stats
@export var cooldown: float = 5.0
@export var damage: int = 20
@export var range: float = 100.0
@export var duration: float = 0.0  # For skills with lasting effects

## Visual effects
@export var skill_color: Color = Color.WHITE
@export var particle_scene: PackedScene

## Skill state
var is_active: bool = false
var owner_player  ## IPlayer interface - injected from parent

## Signals
signal skill_started()
signal skill_ended()
signal hit_target(target: Node3D, damage: int)

## Initialize the skill with its owner
func setup(player) -> void:  ## player: IPlayer interface
	owner_player = player

## Execute the skill - to be overridden by specific skills
func execute() -> void:
	if not owner_player or not owner_player.is_alive:
		return
	
	is_active = true
	skill_started.emit()
	
	# Skill-specific implementation in derived classes
	_perform_skill()
	
	# Handle duration-based skills
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		_end_skill()
	else:
		_end_skill()

## Perform the actual skill effect - override in derived classes
func _perform_skill() -> void:
	push_warning("Skill._perform_skill() not implemented for " + skill_name)

## End the skill effect
func _end_skill() -> void:
	is_active = false
	skill_ended.emit()

## Check if a target is in range
func is_target_in_range(target: Node3D) -> bool:
	if not owner_player:
		return false
	return owner_player.global_position.distance_to(target.global_position) <= range

## Check if a node can be targeted by this skill
func _can_target(target: Node) -> bool:
	if not target:
		return false
	
	# Don't target self
	if target == owner_player:
		return false
	
	# Check if it's a valid targetable entity
	if not target.has_method("take_damage"):
		return false
	
	# Check if target is alive (if applicable)
	if "is_alive" in target and not target.is_alive:
		return false
	
	# Check team/faction if applicable
	if "team" in target and "team" in owner_player:
		if target.team == owner_player.team:
			return false
	
	return true

## Apply damage to a target (legacy method)
func apply_damage_to_target(target: Node3D, damage_multiplier: float = 1.0) -> void:
	if target.has_method("take_damage"):
		var final_damage: int = int(damage * damage_multiplier)
		target.take_damage(final_damage, owner_player)
		hit_target.emit(target, final_damage)

## Apply damage using the new damage system
func apply_damage_info(target: Node3D, damage_type: int = 0,  ## DamageSystem.DamageType (0=PHYSICAL) 
		damage_multiplier: float = 1.0) -> void:
	if not target or not target.has_method("take_damage_info"):
		return
	
	# Create damage info
	var damage_info = DamageSystem.create_skill_damage(
		owner_player,
		target,
		int(damage * damage_multiplier),
		skill_name,
		damage_type
	)
	
	# Apply any additional multipliers from the skill
	damage_info.multiplier = damage_multiplier
	
	# Apply damage
	DamageSystem.apply_damage(damage_info)
	hit_target.emit(target, damage_info.damage_dealt)

## Create visual effect at position
func create_effect(effect_position: Vector3) -> void:
	if particle_scene:
		var effect: Node3D = particle_scene.instantiate()
		get_tree().current_scene.add_child(effect)
		effect.global_position = effect_position
		# Note: modulate property doesn't exist on Node3D - use material override instead 