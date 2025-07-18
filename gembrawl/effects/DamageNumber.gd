## Floating damage number display
## Shows damage values that float up and fade out
class_name DamageNumber
extends Node3D

## Visual settings
@export var float_speed: float = 2.0
@export var float_distance: float = 2.0
@export var lifetime: float = 1.5
@export var scale_popup_time: float = 0.1

## Color settings for different damage types
@export var color_physical: Color = Color.WHITE
@export var color_magical: Color = Color(0.5, 0.5, 1.0)  # Light blue
@export var color_true: Color = Color(1.0, 0.5, 0.5)  # Light red
@export var color_elemental: Color = Color(1.0, 1.0, 0.0)  # Yellow
@export var color_critical: Color = Color(1.0, 0.2, 0.2)  # Bright red
@export var color_heal: Color = Color(0.2, 1.0, 0.2)  # Green

## Components
var label: Label3D
var initial_position: Vector3
var time_elapsed: float = 0.0

func _ready() -> void:
	# Create label
	label = Label3D.new()
	add_child(label)
	
	# Configure label
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.outline_size = 20  # Thicker outline for bigger text
	label.outline_modulate = Color(0, 0, 0, 0.8)
	label.font_size = 96  # 4x bigger for demo visibility
	
	# Store initial position
	initial_position = global_position
	
	# Start with zero scale for popup effect
	scale = Vector3.ZERO

func setup(damage: int, damage_type: DamageSystem.DamageType, is_critical: bool = false, is_heal: bool = false) -> void:
	# Set text
	if is_heal:
		label.text = "+" + str(damage)
		label.modulate = color_heal
	else:
		label.text = str(damage)
		
		# Set color based on damage type and critical
		if is_critical:
			label.modulate = color_critical
			label.text = str(damage) + "!"
			label.font_size = 128  # 4x bigger for criticals
		else:
			match damage_type:
				DamageSystem.DamageType.PHYSICAL:
					label.modulate = color_physical
				DamageSystem.DamageType.MAGICAL:
					label.modulate = color_magical
				DamageSystem.DamageType.TRUE:
					label.modulate = color_true
				DamageSystem.DamageType.ELEMENTAL:
					label.modulate = color_elemental
				_:
					label.modulate = color_physical
	
	# Add random horizontal offset for multiple numbers
	position.x += randf_range(-0.5, 0.5)
	position.z += randf_range(-0.5, 0.5)

func _process(delta: float) -> void:
	time_elapsed += delta
	
	# Scale popup effect
	if time_elapsed < scale_popup_time:
		var popup_progress = time_elapsed / scale_popup_time
		scale = Vector3.ONE * ease(popup_progress, -0.5)
	
	# Float upward
	var float_progress = time_elapsed / lifetime
	position.y = initial_position.y + (float_distance * float_progress)
	
	# Fade out
	if time_elapsed > lifetime * 0.5:
		var fade_progress = (time_elapsed - lifetime * 0.5) / (lifetime * 0.5)
		label.modulate.a = 1.0 - fade_progress
	
	# Destroy when done
	if time_elapsed >= lifetime:
		queue_free()

## Create damage number from scene - removed static method to avoid circular reference issues 