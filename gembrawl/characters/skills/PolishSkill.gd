## Polish skill implementation for GemBrawl
## Provides temporary invulnerability and healing
## Updated for 3D gameplay
class_name PolishSkill
extends Skill

## Polish-specific properties
@export var invulnerability_duration: float = 2.0
@export var heal_amount: int = 25
@export var defense_boost: int = 10
@export var speed_reduction: float = 0.5  # Movement speed multiplier during polish

## Visual shield effect
var shield_sprite: Sprite2D

func _ready() -> void:
	skill_name = "Polish"
	description = "Polish your gem surface to become temporarily invulnerable and restore health"
	cooldown = 8.0
	damage = 0  # Polish doesn't deal damage
	duration = invulnerability_duration
	
	# Create shield visual effect
	shield_sprite = Sprite2D.new()
	add_child(shield_sprite)
	shield_sprite.visible = false

## Perform the polish effect
func _perform_skill() -> void:
	if not owner_player:
		return
	
	# Apply healing
	if owner_player.gem_data:
		owner_player.gem_data.heal(heal_amount)
		owner_player.health_changed.emit(
			owner_player.gem_data.current_health,
			owner_player.gem_data.max_health
		)
	
	# Store original values
	var original_defense: int = owner_player.gem_data.defense if owner_player.gem_data else 0
	var original_speed: float = owner_player.gem_data.movement_speed if owner_player.gem_data else 300.0
	var original_invulnerable: bool = owner_player.invulnerable
	
	# Apply invulnerability
	owner_player.invulnerable = true
	
	# Apply defense boost
	if owner_player.gem_data:
		owner_player.gem_data.defense += defense_boost
		owner_player.gem_data.movement_speed *= speed_reduction
	
	# Show shield effect
	_show_shield_effect()
	
	# Create polish particle effect
	create_effect(owner_player.global_position)
	
	# Wait for duration
	await get_tree().create_timer(duration).timeout
	
	# Restore original values
	owner_player.invulnerable = original_invulnerable
	if owner_player.gem_data:
		owner_player.gem_data.defense = original_defense
		owner_player.gem_data.movement_speed = original_speed
	
	# Hide shield effect
	_hide_shield_effect()

## Show the shield visual effect
func _show_shield_effect() -> void:
	if not shield_sprite:
		return
	
	shield_sprite.visible = true
	
	# Create a pulsing effect
	var tween: Tween = create_tween()
	tween.set_loops()
	tween.tween_property(shield_sprite, "modulate:a", 0.3, 0.5)
	tween.tween_property(shield_sprite, "modulate:a", 0.7, 0.5)
	
	# Add rotation
	var rotation_tween: Tween = create_tween()
	rotation_tween.set_loops()
	rotation_tween.tween_property(shield_sprite, "rotation", TAU, 3.0)

## Hide the shield visual effect
func _hide_shield_effect() -> void:
	if not shield_sprite:
		return
	
	# Stop all tweens
	shield_sprite.visible = false
	var tweens: Array[Tween] = get_tree().get_processed_tweens()
	for tween in tweens:
		if tween.is_valid():
			tween.kill()

## Override end skill to ensure effects are removed
func _end_skill() -> void:
	_hide_shield_effect()
	super._end_skill() 