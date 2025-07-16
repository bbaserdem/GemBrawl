## Shine skill implementation for GemBrawl
## Creates a radiant burst that damages all nearby enemies
##
## WARNING: This skill implementation contains legacy 2D references
## and needs to be updated for 3D gameplay. Vector2 types should be
## changed to Vector3, and Node2D references should be Node3D.
## This will be addressed when implementing Task 6 or Task 20.
class_name ShineSkill
extends Skill

## Shine-specific properties
@export var blast_radius: float = 150.0
@export var blind_duration: float = 1.5
@export var knockback_force: float = 300.0
@export var inner_radius_multiplier: float = 0.5  # Inner radius deals more damage

## Visual blast effect
var blast_area: Area2D
var blast_shape: CollisionShape2D
var blast_sprite: Sprite2D

func _ready() -> void:
	skill_name = "Shine"
	description = "Release a brilliant radial blast that damages and blinds nearby enemies"
	cooldown = 6.0
	damage = 40
	range = blast_radius
	
	# Create blast area for detection
	blast_area = Area2D.new()
	add_child(blast_area)
	blast_area.monitoring = false
	blast_area.monitorable = false
	
	# Create collision shape for blast
	blast_shape = CollisionShape2D.new()
	var circle_shape: CircleShape2D = CircleShape2D.new()
	circle_shape.radius = blast_radius
	blast_shape.shape = circle_shape
	blast_area.add_child(blast_shape)
	
	# Create visual effect sprite
	blast_sprite = Sprite2D.new()
	add_child(blast_sprite)
	blast_sprite.visible = false

## Perform the shine blast
func _perform_skill() -> void:
	if not owner_player:
		return
	
	# Position blast at player location
	blast_area.global_position = owner_player.global_position
	
	# Show blast visual effect
	_show_blast_effect()
	
	# Enable area detection
	blast_area.monitoring = true
	await get_tree().process_frame  # Wait for physics to update
	
	# Get all bodies in blast radius
	var bodies: Array[Node2D] = blast_area.get_overlapping_bodies()
	var areas: Array[Area2D] = blast_area.get_overlapping_areas()
	
	# Combine bodies and areas
	var targets: Array[Node2D] = []
	targets.append_array(bodies)
	for area in areas:
		if area.get_parent() != owner_player:
			targets.append(area.get_parent())
	
	# Apply damage and effects to each target
	for target in targets:
		if target == owner_player:
			continue
			
		if target.has_method("take_damage"):
			# Calculate damage based on distance (closer = more damage)
			var distance: float = owner_player.global_position.distance_to(target.global_position)
			var damage_multiplier: float = 1.0
			
			if distance <= blast_radius * inner_radius_multiplier:
				damage_multiplier = 1.5  # 50% more damage in inner radius
			else:
				damage_multiplier = 1.0 - (distance / blast_radius) * 0.5  # Falloff damage
			
			apply_damage_to_target(target, damage_multiplier)
			
			# Apply knockback
			_apply_knockback(target)
			
			# Apply blind effect
			_apply_blind_effect(target)
			
			# Create hit effect
			create_effect(target.global_position)
	
	# Disable area detection
	blast_area.monitoring = false
	
	# Create central blast effect
	create_effect(owner_player.global_position)

## Apply knockback to a target
func _apply_knockback(target: Node2D) -> void:
	if not target.has_property("velocity"):
		return
		
	var knockback_direction: Vector2 = (target.global_position - owner_player.global_position).normalized()
	target.velocity = knockback_direction * knockback_force

## Apply blind effect to target
func _apply_blind_effect(target: Node2D) -> void:
	# This would apply a status effect that reduces accuracy or vision
	# For now, we'll just signal that the target was blinded
	if target.has_signal("status_effect_applied"):
		target.emit_signal("status_effect_applied", "blind", blind_duration)

## Show the blast visual effect
func _show_blast_effect() -> void:
	if not blast_sprite:
		return
		
	blast_sprite.visible = true
	blast_sprite.scale = Vector2.ZERO
	blast_sprite.modulate = skill_color
	blast_sprite.modulate.a = 0.8
	
	# Expand blast effect
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(blast_sprite, "scale", Vector2.ONE * (blast_radius / 50.0), 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(blast_sprite, "modulate:a", 0.0, 0.5)
	
	await tween.finished
	blast_sprite.visible = false

## Create a ring of particles around the blast
func _create_blast_particles() -> void:
	var particle_count: int = 12
	for i in particle_count:
		var angle: float = (TAU / particle_count) * i
		var particle_pos: Vector2 = owner_player.global_position + Vector2.RIGHT.rotated(angle) * blast_radius * 0.8
		create_effect(particle_pos) 