## Visual indicator for AoE attacks
## Shows warning zone before damage
extends Node3D

@export var color_warning: Color = Color(1, 0.5, 0, 0.5)  # Orange warning
@export var color_danger: Color = Color(1, 0, 0, 0.7)     # Red danger
@export var fade_speed: float = 2.0

var mesh_instance: MeshInstance3D
var material: StandardMaterial3D
var time_elapsed: float = 0.0
var duration: float = 1.0

func setup(radius: float, shape: int, warning_duration: float) -> void:
	duration = warning_duration
	
	# Create mesh based on shape
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	match shape:
		0:  # SPHERE
			var cylinder_mesh = CylinderMesh.new()
			cylinder_mesh.height = 0.1
			cylinder_mesh.top_radius = radius
			cylinder_mesh.bottom_radius = radius
			mesh_instance.mesh = cylinder_mesh
		_:
			# Default to sphere shape
			var cylinder_mesh = CylinderMesh.new()
			cylinder_mesh.height = 0.1
			cylinder_mesh.top_radius = radius
			cylinder_mesh.bottom_radius = radius
			mesh_instance.mesh = cylinder_mesh
	
	# Create material
	material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color_warning
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = material

func _process(delta: float) -> void:
	time_elapsed += delta
	
	# Pulse effect
	var pulse = sin(time_elapsed * 10.0) * 0.1 + 0.9
	material.albedo_color.a = color_warning.a * pulse
	
	# Transition to danger color
	var progress = time_elapsed / duration
	material.albedo_color = color_warning.lerp(color_danger, progress) 