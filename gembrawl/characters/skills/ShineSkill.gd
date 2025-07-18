## Shine skill implementation for GemBrawl
## An area-of-effect blast that damages and knocks back enemies
## Updated for 3D gameplay
class_name ShineSkill
extends Skill

## Shine-specific properties
@export var blast_radius: float = 150.0
@export var knockback_power: float = 400.0
@export var blast_duration: float = 0.5

## Visual effect nodes
var blast_area: Area3D
var blast_visual: MeshInstance3D
var blast_particles: GPUParticles3D

func _ready() -> void:
	skill_name = "Shine"
	description = "Release a radiant blast, damaging and knocking back all nearby enemies"
	cooldown = 6.0
	damage = 25
	range = blast_radius
	
	# Create blast area for detection
	blast_area = Area3D.new()
	add_child(blast_area)
	
	# Add collision shape
	var collision_shape: CollisionShape3D = CollisionShape3D.new()
	var sphere_shape: SphereShape3D = SphereShape3D.new()
	sphere_shape.radius = blast_radius
	collision_shape.shape = sphere_shape
	blast_area.add_child(collision_shape)
	
	# Configure collision layers
	blast_area.collision_layer = 0
	blast_area.collision_mask = 0b0010  # Enemy layer
	blast_area.monitoring = false
	
	# Create visual effect (sphere mesh)
	blast_visual = MeshInstance3D.new()
	var sphere_mesh: SphereMesh = SphereMesh.new()
	sphere_mesh.radial_segments = 32
	sphere_mesh.rings = 16
	sphere_mesh.radius = blast_radius
	sphere_mesh.height = blast_radius * 2
	blast_visual.mesh = sphere_mesh
	blast_visual.scale = Vector3.ZERO
	add_child(blast_visual)

## Perform the shine blast
func _perform_skill() -> void:
	if not owner_player:
		return
	
	# Position blast at player location
	blast_area.global_position = owner_player.global_position
	
	# Enable area detection
	blast_area.monitoring = true
	
	# Get all bodies in range
	await get_tree().physics_frame
	var bodies: Array[Node3D] = blast_area.get_overlapping_bodies()
	var areas: Array[Area3D] = blast_area.get_overlapping_areas()
	
	# Process all targets
	var targets_hit: int = 0
	
	for body in bodies:
		if _can_target(body):
			_apply_shine_damage(body)
			targets_hit += 1
	
	for area in areas:
		var parent: Node = area.get_parent()
		if parent and _can_target(parent):
			_apply_shine_damage(parent)
			targets_hit += 1
	
	# Visual feedback based on hits
	if targets_hit > 0:
		# Create hit effects on each target
		for body in bodies:
			if _can_target(body):
				create_effect(body.global_position)
	
	# Create central blast effect
	_create_blast_visual()
	
	# Disable area after effect
	await get_tree().create_timer(blast_duration).timeout
	blast_area.monitoring = false
	
	# Always create effect at player position
	create_effect(owner_player.global_position)

## Apply damage and knockback to a single target
func _apply_shine_damage(target: Node3D) -> void:
	# Apply damage
	apply_damage_to_target(target)
	
	# Calculate and apply knockback
	var knockback_direction: Vector3 = (target.global_position - owner_player.global_position).normalized()
	knockback_direction.y = 0  # Keep knockback horizontal
	
	if "velocity" in target:
		target.velocity += knockback_direction * knockback_power
	elif target.has_method("apply_knockback"):
		target.apply_knockback(knockback_direction * knockback_power)

## Create the visual blast effect
func _create_blast_visual() -> void:
	if not blast_visual:
		return
	
	# Reset scale
	blast_visual.scale = Vector3.ZERO
	blast_visual.visible = true
	
	# Animate the blast expansion
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	
	# Scale up
	tween.tween_property(blast_visual, "scale", Vector3.ONE * (blast_radius / 50.0), 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	
	# Fade out (requires material with transparency)
	if blast_visual.material_override and "albedo_color" in blast_visual.material_override:
		var start_color: Color = blast_visual.material_override.albedo_color
		var end_color: Color = Color(start_color.r, start_color.g, start_color.b, 0.0)
		tween.tween_property(blast_visual.material_override, "albedo_color", end_color, 0.3)
	
	tween.tween_callback(func(): blast_visual.visible = false).set_delay(0.3)
	
	# Create particle ring effect
	for i in range(8):
		var angle: float = (TAU / 8.0) * i
		var particle_pos: Vector3 = owner_player.global_position + Vector3(cos(angle), 0, sin(angle)) * blast_radius * 0.8
		create_effect(particle_pos)