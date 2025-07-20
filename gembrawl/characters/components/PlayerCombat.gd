## PlayerCombat - Handles player combat mechanics
## Manages damage, defense, invulnerability, and skill usage
class_name PlayerCombat
extends Node

# Ensure DamageSystem is loaded and available as constant
const DamageSystem = preload("res://scripts/DamageSystem.gd")

## Combat settings
@export var invulnerability_duration: float = 0.5

## Combat state
var invulnerable: bool = false
var skill_ready: bool = true
var skill_cooldown_timer: float = 0.0

## References
var player: IPlayer
var gem_data  # Gem resource

## Signals - untyped parameters to avoid dependency issues
signal damage_dealt(damage_info)
signal damage_received(damage_info)
signal skill_used()

# Player is now injected from parent instead of getting from get_parent()

## Initialize combat component
func setup(gem) -> void:
	gem_data = gem

## Process combat updates
func process_combat(delta: float) -> void:
	# Update skill cooldown
	if not skill_ready:
		skill_cooldown_timer -= delta
		if skill_cooldown_timer <= 0:
			skill_ready = true

## Take damage from an attack (legacy method)
func take_damage(damage: int, attacker: Node3D = null) -> bool:
	if invulnerable or not player.is_alive() or player.is_spectator():
		return false
	
	var is_defeated = gem_data.take_damage(damage)
	# Emit health_changed signal through the player's stats component
	if player.get_stats():
		player.get_stats().health_changed.emit(gem_data.current_health, gem_data.max_health)
	
	if not is_defeated:
		# Trigger invulnerability and visual feedback
		start_invulnerability()
	
	return is_defeated

## Take damage using the new damage system
func take_damage_info(damage_info) -> bool:
	if invulnerable or not player.is_alive() or player.is_spectator():
		damage_info.damage_dealt = 0
		return false
	
	# Apply damage through the damage system
	DamageSystem.calculate_damage(damage_info)
	print("Player - Base: ", damage_info.base_damage, " Final: ", damage_info.damage_dealt)
	
	# Show damage number
	if damage_info.damage_dealt > 0:
		_show_damage_number(damage_info)
	
	# Apply the calculated damage
	var is_defeated = gem_data.take_damage(damage_info.damage_dealt)
	# Emit health_changed signal through the player's stats component
	if player.get_stats():
		player.get_stats().health_changed.emit(gem_data.current_health, gem_data.max_health)
	damage_received.emit(damage_info)
	
	if not is_defeated:
		# Trigger invulnerability and visual feedback
		start_invulnerability()
	
	return is_defeated

## Get defense value against specific damage type
func get_defense_against(damage_type) -> int:
	if not gem_data:
		return 0
	
	match damage_type:
		DamageSystem.DamageType.PHYSICAL:
			return gem_data.defense
		DamageSystem.DamageType.MAGICAL:
			return gem_data.magic_resistance
		DamageSystem.DamageType.TRUE:
			return 0  # True damage ignores defense
		DamageSystem.DamageType.ELEMENTAL:
			return gem_data.magic_resistance  # Use magic resist for elemental
		_:
			return 0

## Get this player's element type
func get_element() -> String:
	if gem_data:
		return gem_data.element
	return ""

## Start invulnerability period
func start_invulnerability(duration_override: float = -1.0) -> void:
	invulnerable = true
	var duration = duration_override if duration_override > 0 else invulnerability_duration
	
	# Visual feedback for invulnerability (flashing effect)
	_apply_invulnerability_visual(duration)
	
	await get_tree().create_timer(duration).timeout
	invulnerable = false

## Apply visual feedback for invulnerability
func _apply_invulnerability_visual(duration: float) -> void:
	var mesh_instance = player.get_node_or_null("MeshInstance3D") if player else null
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override
		if material is StandardMaterial3D:
			var tween = create_tween()
			tween.set_loops(int(duration * 4))  # Flash 4 times per second
			tween.tween_property(material, "albedo_color:a", 0.3, 0.125)
			tween.tween_property(material, "albedo_color:a", 1.0, 0.125)

## Show damage number effect
func _show_damage_number(damage_info) -> void:
	var damage_number_scene = preload("res://effects/DamageNumber.tscn")
	var damage_number = damage_number_scene.instantiate()
	get_tree().current_scene.add_child(damage_number)
	damage_number.global_position = player.get_global_position() + Vector3(0, 1.5, 0)
	damage_number.setup(
		damage_info.damage_dealt,
		damage_info.damage_type,
		damage_info.is_critical
	)

## Use the gem's special skill
func use_skill() -> bool:
	if not skill_ready or not player.is_alive():
		return false
	
	skill_ready = false
	skill_cooldown_timer = gem_data.skill_cooldown
	skill_used.emit()
	return true

## Check if skill is ready
func is_skill_ready() -> bool:
	return skill_ready

## Get remaining cooldown time
func get_skill_cooldown_remaining() -> float:
	return skill_cooldown_timer if not skill_ready else 0.0